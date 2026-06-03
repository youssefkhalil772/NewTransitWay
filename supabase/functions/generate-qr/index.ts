import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { driverId } = await req.json();

    if (!driverId) {
      return new Response(JSON.stringify({ error: "driverId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Step 1: Get the bus assigned to this driver
    let { data: driverData, error: driverError } = await supabase
      .from("drivers")
      .select("\"busId\", email")
      .eq("id", driverId)
      .maybeSingle();

    // If not found by ID, try to find by matching auth user email
    if (!driverData?.busId) {
      const { data: authUser } = await supabase.auth.admin.getUserById(driverId);
      const email = authUser?.user?.email;
      if (email) {
        const { data: driverByEmail } = await supabase
          .from("drivers")
          .select("\"busId\"")
          .eq("email", email)
          .maybeSingle();
        if (driverByEmail?.busId) {
          (driverData as any) = driverByEmail;
        }
      }
    }

    if (!driverData?.busId) {
      return new Response(JSON.stringify({ error: "No bus assigned to driver" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Step 2: Get bus info
    const { data: busData, error: busError } = await supabase
      .from("buses")
      .select("id, bus_number")
      .eq("id", driverData.busId)
      .maybeSingle();

    if (busError || !busData) {
      return new Response(JSON.stringify({ error: "Bus not found" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Step 3: Get OR create a static QR for this bus (no trip required)
    const { data: existingQr } = await supabase
      .from("route_qrs")
      .select("id, token, route_id")
      .eq("bus_id", busData.id)
      .order("created_at", { ascending: true })
      .limit(1)
      .maybeSingle();

    let token: string;
    let routeId: string | null = null;

    if (existingQr?.token) {
      // Reuse the same token (even if trip closed)
      token = existingQr.token;
      routeId = existingQr.route_id;
    } else {
      // No QR exists yet — check if there's an active trip to get route_id
      const { data: trip } = await supabase
        .from("trips")
        .select("route_id")
        .eq("bus_id", busData.id)
        .is("end_time", null)
        .maybeSingle();

      token = crypto.randomUUID().replace(/-/g, "").toUpperCase();
      routeId = trip?.route_id ?? null;

      await supabase.from("route_qrs").insert({
        route_id: routeId,
        bus_id: busData.id,
        driver_id: driverId,
        token: token,
        qr_code: token,
        is_active: true,
      });
    }

    // Step 4: Update is_active based on whether there's an active trip now
    const { data: activeTrip } = await supabase
      .from("trips")
      .select("id, route_id")
      .eq("bus_id", busData.id)
      .is("end_time", null)
      .maybeSingle();

    const isActive = !!activeTrip;

    // Update the QR: sync is_active and route_id with current trip
    if (existingQr?.id) {
      await supabase
        .from("route_qrs")
        .update({
          is_active: isActive,
          route_id: activeTrip?.route_id ?? existingQr.route_id,
          driver_id: driverId,
        })
        .eq("id", existingQr.id);
      if (activeTrip?.route_id) routeId = activeTrip.route_id;
    }

    // Step 5: Get route info if we have a route_id
    let routeName = "Route Info Unavailable";
    let price: number | null = null;

    if (routeId) {
      const { data: routeData } = await supabase
        .from("routes")
        .select("name, start_point, price")
        .eq("id", routeId)
        .maybeSingle();

      if (routeData) {
        routeName = routeData.name ?? routeData.start_point ?? "Unknown Route";
        price = routeData.price ?? null;
      }
    }

    return new Response(JSON.stringify({
      token,
      routeName,
      price,
      busId: busData.id,
      busNumber: busData.bus_number,
      tripActive: isActive,
    }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
