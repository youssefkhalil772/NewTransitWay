import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { userId, qrToken } = await req.json();

    if (!userId || !qrToken) {
      return new Response(
        JSON.stringify({ error: "userId and qrToken are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Verify User
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("*")
      .eq("id", userId)
      .single();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "User not found" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Verify QR is active
    const { data: routeQr, error: qrError } = await supabase
      .from("route_qrs")
      .select("*")
      .eq("token", qrToken)
      .eq("is_active", true)
      .single();

    if (qrError || !routeQr) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired QR" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Verify Active Trip on this bus (ended_at is null)
    const { data: activeTrip, error: tripError } = await supabase
      .from("trips")
      .select("*")
      .eq("bus_id", routeQr.bus_id)
      .is("ended_at", null)
      .single();

    if (tripError || !activeTrip) {
      return new Response(
        JSON.stringify({ error: "No active trip on this bus" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Get route info and price
    const { data: route, error: routeError } = await supabase
      .from("routes")
      .select("*, zones(*)")
      .eq("id", routeQr.route_id)
      .single();

    if (routeError || !route || !route.zones) {
      return new Response(
        JSON.stringify({ error: "Route or zone not found" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fare = route.zones.price;

    // 5. Verify wallet balance
    const { data: wallet, error: walletError } = await supabase
      .from("wallets")
      .select("*")
      .eq("user_id", userId)
      .single();

    if (walletError || !wallet || wallet.balance < fare) {
      return new Response(
        JSON.stringify({ error: "Insufficient balance" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Deduct balance
    const { error: walletUpdateError } = await supabase
      .from("wallets")
      .update({ balance: wallet.balance - fare })
      .eq("user_id", userId);

    if (walletUpdateError) {
      return new Response(
        JSON.stringify({ error: `Failed to deduct balance: ${walletUpdateError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Create ticket
    const ticketCode = "TICKET-" + crypto.randomUUID().substring(0, 8).toUpperCase();
    const { data: ticket, error: ticketError } = await supabase
      .from("tickets")
      .insert({
        user_id: userId,
        route_id: routeQr.route_id,
        bus_id: routeQr.bus_id,
        ticket_code: ticketCode,
        status: "active",
      })
      .select()
      .single();

    if (ticketError) {
      // Rollback wallet if we want to be safe, but ignore for now
      return new Response(
        JSON.stringify({ error: `Failed to create ticket: ${ticketError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "Fare paid successfully",
        ticketId: ticket.id,
        routeName: route.name,
        fare: fare,
        remainingBalance: wallet.balance - fare,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
