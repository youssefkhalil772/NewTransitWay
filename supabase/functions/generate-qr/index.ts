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
    const { driverId } = await req.json();

    if (!driverId) {
      return new Response(
        JSON.stringify({ error: "driverId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Step 1: Get the bus assigned to this driver
    const { data: driverData, error: driverError } = await supabase
      .from("drivers")
      .select("bus_id")
      .eq("id", driverId)
      .maybeSingle();

    if (driverError || !driverData?.bus_id) {
      return new Response(
        JSON.stringify({ error: "No bus assigned to driver" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 2: Get the active trip for this bus
    const { data: trip, error: tripError } = await supabase
      .from("trips")
      .select("route_id")
      .eq("bus_id", driverData.bus_id)
      .is("ended_at", null)
      .maybeSingle();

    if (tripError || !trip) {
      return new Response(
        JSON.stringify({ error: "No active trip for this bus" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 3: Get the bus info (for bus number)
    const { data: busData, error: busError } = await supabase
      .from("buses")
      .select("id, bus_number, status")
      .eq("id", driverData.bus_id)
      .maybeSingle();

    if (busError || !busData) {
      return new Response(
        JSON.stringify({ error: "Bus not found" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 4: Get the route name and price
    const { data: routeData, error: routeError } = await supabase
      .from("lines")
      .select("start_point, end_point, price")
      .eq("line_number", trip.route_id)
      .maybeSingle();

    if (routeError || !routeData) {
      return new Response(
        JSON.stringify({ error: "Route information not found" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 5: Check if there's already an active QR for this bus
    const { data: existingQr } = await supabase
      .from("route_qrs")
      .select("token")
      .eq("bus_id", busData.id)
      .eq("is_active", true)
      .maybeSingle();

    let token = existingQr?.token;

    // Step 6: If no active QR, generate a new one
    if (!token) {
      token = crypto.randomUUID().replace(/-/g, "").toUpperCase();
      const { error: insertError } = await supabase
        .from("route_qrs")
        .insert({
          route_id: trip.route_id,
          bus_id: busData.id,
          driver_id: driverId,
          token: token,
          qr_code: token,
          is_active: true,
        });

      if (insertError) {
        return new Response(
          JSON.stringify({ error: `Failed to insert QR: ${insertError.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    return new Response(
      JSON.stringify({
        token,
        routeName: routeData.start_point ? `${routeData.start_point}` : `${trip.route_id}`,
        price: routeData.price,
        busId: busData.id,
        busNumber: busData.bus_number,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
