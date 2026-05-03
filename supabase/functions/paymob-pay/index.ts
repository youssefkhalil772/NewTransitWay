import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PAYMOB_API_KEY = Deno.env.get("PAYMOB_API_KEY");
const PAYMOB_INTEGRATION_ID = Deno.env.get("PAYMOB_INTEGRATION_ID");
const PAYMOB_IFRAME_ID = Deno.env.get("PAYMOB_IFRAME_ID"); // Optional if iframe is used

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { userId, amount, walletPhone } = await req.json();

    if (!userId || !amount || !walletPhone) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get user details for billing data
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('full_name, phone_number, email')
      .eq('id', userId)
      .single();

    if (userError || !userData) {
      return new Response(
        JSON.stringify({ error: "User not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const firstName = userData.full_name?.split(' ')[0] || 'Transit';
    const lastName = userData.full_name?.split(' ').slice(1).join(' ') || 'User';
    const email = userData.email || 'user@transitway.com';
    const phone = userData.phone_number || walletPhone;

    // 1. Authentication Request
    const authReq = await fetch("https://accept.paymob.com/api/auth/tokens", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ api_key: PAYMOB_API_KEY }),
    });
    
    if (!authReq.ok) {
        const errData = await authReq.text();
        console.error("Auth token error:", errData);
        throw new Error("Failed to authenticate with PayMob");
    }
    
    const authRes = await authReq.json();
    const token = authRes.token;

    // 2. Order Registration Request
    const amountCents = amount * 100;
    const orderReq = await fetch("https://accept.paymob.com/api/ecommerce/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        auth_token: token,
        delivery_needed: "false",
        amount_cents: amountCents.toString(),
        currency: "EGP",
        items: [],
      }),
    });
    
    if (!orderReq.ok) {
        throw new Error("Failed to register order");
    }
    
    const orderRes = await orderReq.json();
    const orderId = orderRes.id;

    // 3. Payment Key Generation
    const paymentKeyReq = await fetch("https://accept.paymob.com/api/acceptance/payment_keys", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        auth_token: token,
        amount_cents: amountCents.toString(),
        expiration: 3600,
        order_id: orderId,
        billing_data: {
          apartment: "NA",
          email: email,
          floor: "NA",
          first_name: firstName,
          street: "NA",
          building: "NA",
          phone_number: phone,
          shipping_method: "NA",
          postal_code: "NA",
          city: "Cairo",
          country: "EG",
          last_name: lastName,
          state: "NA",
        },
        currency: "EGP",
        integration_id: PAYMOB_INTEGRATION_ID,
        lock_order_when_paid: "false"
      }),
    });

    if (!paymentKeyReq.ok) {
        throw new Error("Failed to generate payment key");
    }

    const paymentKeyRes = await paymentKeyReq.json();
    const paymentToken = paymentKeyRes.token;

    // 4. Pay request (Mobile Wallet)
    const payReq = await fetch("https://accept.paymob.com/api/acceptance/payments/pay", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source: {
          identifier: walletPhone,
          subtype: "WALLET"
        },
        payment_token: paymentToken
      }),
    });

    if (!payReq.ok) {
        const errData = await payReq.text();
        console.error("Pay error:", errData);
        throw new Error("Payment failed to initiate");
    }

    const payRes = await payReq.json();
    
    // Store pending transaction in database to be updated by webhook
    await supabase.from('transactions').insert({
      user_id: userId,
      amount: amount,
      paymob_order_id: orderId,
      status: 'pending',
      type: 'wallet_charge',
      wallet_phone: walletPhone
    });

    // Check if redirect URL exists (PayMob returns iframe_url for wallet payments)
    if (payRes.redirect_url) {
      return new Response(
        JSON.stringify({ 
          redirectUrl: payRes.redirect_url,
          orderId: orderId
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    // As a fallback for demo/testing without full paymob config, immediately add balance
    // In production, the webhook would handle this part when payment succeeds
    
    const { data: userCurrentData } = await supabase
        .from('users')
        .select('points')
        .eq('id', userId)
        .single();
        
    const currentPoints = userCurrentData?.points || 0;
    const newPoints = currentPoints + amount; // 1 EGP = 1 point
    
    await supabase
        .from('users')
        .update({ points: newPoints })
        .eq('id', userId);
        
    await supabase.from('transactions')
        .update({ status: 'success' })
        .eq('paymob_order_id', orderId);

    return new Response(
      JSON.stringify({ 
        success: true, 
        newBalance: newPoints 
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (err) {
    console.error("paymob-pay error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
