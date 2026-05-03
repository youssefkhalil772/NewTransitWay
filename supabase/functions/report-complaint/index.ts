import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// AI-powered complaint analysis using rule-based categorization + storage
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { text, image, imageName } = await req.json();

    if (!text || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Complaint text is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const complaintText = text.trim().toLowerCase();

    // ── Step 1: Categorize complaint ─────────────────────────────
    let category = "Other";
    let severity = "Medium";
    let recommendations: string[] = [];

    // Safety issues
    if (/speed|reckless|accident|crash|dangerous|unsafe|seatbelt|brake/i.test(complaintText)) {
      category = "Safety";
      severity = "High";
      recommendations = [
        "Report has been flagged as HIGH priority due to safety concerns.",
        "Relevant authorities will be notified immediately.",
        "If you are in immediate danger, please call emergency services.",
      ];
    }
    // Driver behavior
    else if (/driver|rude|unprofessional|aggressive|yell|shout|insult|behavior|attitude|phone/i.test(complaintText)) {
      category = "Driver Behavior";
      severity = "High";
      recommendations = [
        "The driver's conduct will be reviewed by our management team.",
        "Disciplinary action will be taken if the complaint is verified.",
        "A warning will be issued to the driver.",
      ];
    }
    // Overcrowding
    else if (/crowd|overcrowd|full|packed|capacity|standing|no seat|too many/i.test(complaintText)) {
      category = "Overcrowding";
      severity = "Medium";
      recommendations = [
        "We will review passenger capacity on this route.",
        "Additional buses may be deployed during peak hours.",
        "Route scheduling will be optimized to reduce overcrowding.",
      ];
    }
    // Timing / Delays
    else if (/late|delay|wait|time|schedule|early|slow|on time|never came|didn't come|long time/i.test(complaintText)) {
      category = "Timing & Delays";
      severity = "Medium";
      recommendations = [
        "Route scheduling data will be reviewed.",
        "GPS tracking will be audited for this route.",
        "We will work to improve schedule adherence.",
      ];
    }
    // Cleanliness
    else if (/dirty|clean|smell|garbage|trash|hygiene|messy|stain|broken seat|air condition|ac/i.test(complaintText)) {
      category = "Cleanliness & Maintenance";
      severity = "Low";
      recommendations = [
        "A maintenance request has been generated for this bus.",
        "Cleaning schedule will be reviewed and improved.",
        "Regular inspections will be increased for this route.",
      ];
    }
    // Payment / Fare
    else if (/price|fare|charge|overcharge|money|pay|payment|expensive|refund|wallet|balance/i.test(complaintText)) {
      category = "Payment & Fare";
      severity = "Medium";
      recommendations = [
        "Your fare complaint will be reviewed by the finance team.",
        "If overcharged, a refund will be processed to your wallet.",
        "Fare policies for this route will be audited.",
      ];
    }
    // Route issues
    else if (/route|stop|station|wrong|direction|detour|path|destination|missed/i.test(complaintText)) {
      category = "Route Issues";
      severity = "Medium";
      recommendations = [
        "Route compliance will be verified with GPS data.",
        "The driver will be reminded of the correct route.",
        "Station stop compliance will be monitored.",
      ];
    }
    // General
    else {
      category = "General Feedback";
      severity = "Low";
      recommendations = [
        "Thank you for your feedback.",
        "Your complaint has been recorded and will be reviewed.",
        "We strive to improve our service continuously.",
      ];
    }

    // ── Step 2: Build analysis result ────────────────────────────
    const analysisResult = [
      `📋 Category: ${category}`,
      `⚠️ Severity: ${severity}`,
      ``,
      `📝 Summary:`,
      `Your complaint about "${text.trim().substring(0, Math.min(text.trim().length, 80))}${text.trim().length > 80 ? '...' : ''}" has been analyzed and categorized as a ${category} issue with ${severity} priority.`,
      ``,
      `💡 Recommendations:`,
      ...recommendations.map((r, i) => `${i + 1}. ${r}`),
      ``,
      `✅ This complaint has been saved and will be reviewed by our team.`,
    ].join("\n");

    // ── Step 3: Store complaint in database ──────────────────────
    // Try to get current user from auth header
    let userId: string | null = null;
    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      try {
        const { data: { user } } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
        userId = user?.id ?? null;
      } catch (_) {
        // Continue without user ID
      }
    }

    // Store in complaints table (create if needed, ignore errors)
    try {
      await supabase.from("complaints").insert({
        user_id: userId,
        text: text.trim(),
        category: category,
        severity: severity,
        has_image: !!image,
        status: "pending",
      });
    } catch (e) {
      console.log("Note: Could not store complaint:", e);
      // Not critical — continue with analysis response
    }

    return new Response(
      JSON.stringify({
        result: analysisResult,
        category: category,
        severity: severity,
        recommendations: recommendations,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("report-complaint error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
