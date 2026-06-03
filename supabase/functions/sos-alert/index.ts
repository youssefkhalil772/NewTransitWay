import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body = await req.json();
    const { action, driver_id, bus_id, latitude, longitude, alert_id, message } = body;

    if (action === "trigger") {
      if (!driver_id || !bus_id) {
        return new Response(
          JSON.stringify({ error: "driver_id and bus_id are required" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Insert SOS alert
      const insertData: any = {
        driver_id,
        bus_id,
        latitude: latitude ?? 0.0,
        longitude: longitude ?? 0.0,
        status: "Pending",
      };
      
      if (message) {
        insertData.message = message;
      }

      const { data: alert, error } = await supabase
        .from("sos_alerts")
        .insert(insertData)
        .select("id")
        .single();

      if (error) {
        console.error("SOS insert error:", error);
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ data: { alertId: alert.id } }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "safe") {
      if (!alert_id) {
        return new Response(
          JSON.stringify({ error: "alert_id is required" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabase
        .from("sos_alerts")
        .update({ status: "Safe", resolved_at: new Date().toISOString() })
        .eq("id", alert_id);

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "emergency") {
      if (!alert_id) {
        return new Response(
          JSON.stringify({ error: "alert_id is required" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await supabase
        .from("sos_alerts")
        .update({ status: "Emergency" })
        .eq("id", alert_id);

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (e) {
    console.error("sos-alert error:", e);
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
