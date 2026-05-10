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
    const { driverId, numberOfTickets } = await req.json();

    if (!driverId || !numberOfTickets || numberOfTickets <= 0) {
      return new Response(
        JSON.stringify({ error: "driverId and numberOfTickets are required" }),
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
    const busId = driverData.bus_id;

    // Step 2: Get active trip
    const { data: trip, error: tripError } = await supabase
      .from("trips")
      .select("route_id")
      .eq("bus_id", busId)
      .is("ended_at", null)
      .maybeSingle();

    if (tripError || !trip) {
      return new Response(
        JSON.stringify({ error: "No active trip for this bus" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Step 3: Get route price and name
    const { data: routeData, error: routeError } = await supabase
      .from("lines")
      .select("line_number, start_point, price")
      .eq("line_number", trip.route_id)
      .maybeSingle();

    if (routeError || !routeData || !routeData.price) {
      return new Response(
        JSON.stringify({ error: "Invalid ticket price" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const now = new Date().toISOString();

    // Step 4: Insert tickets into the database
    // Removed driver_id, number_of_tickets, and price because they are not in the schema.
    // We use user_id to store the driverId, and generate a ticket_code.
    const ticketsToInsert = Array.from({ length: numberOfTickets }, () => ({
      user_id: driverId,
      bus_id: busId,
      route_id: routeData.line_number,
      ticket_code: "MANUAL-" + crypto.randomUUID().substring(0, 8).toUpperCase(),
      status: "active"
    }));

    const { data: insertedTickets, error: insertError } = await supabase
      .from("tickets")
      .insert(ticketsToInsert)
      .select("id");

    if (insertError) {
      return new Response(
        JSON.stringify({ error: `Failed to create tickets: ${insertError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        message: "Tickets created successfully",
        routeName: routeData.start_point ? `${routeData.start_point}` : `${routeData.line_number}`,
        pricePerTicket: routeData.price,
        numberOfTickets,
        dateTime: now,
        ticketIds: insertedTickets?.map((t: { id: string }) => t.id) ?? [],
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
