const C = {
  bg: "#111827",
  deep: "#0B1220",
  panel: "#1F2937",
  panel2: "#243244",
  border: "#3D4A5F",
  white: "#F8FAFC",
  light: "#CBD5E1",
  muted: "#94A3B8",
  blue: "#5B8FF0",
  blue2: "#1557C0",
  orange: "#FF9A3D",
  orange2: "#FF7A00",
};

const FONT = "Segoe UI";

export const CONTENT = {
  1: { num: "01", presenter: "Allen", title: "Local Service E-Commerce Marketplace", lead: "For independent service providers and clients", lines: ["Discover, compare, book, and manage local services", "One organized platform for the full service transaction"] },
  2: { num: "02", presenter: "Jeremiah", lead: "Ideation starting point", title: "How Might We", quote: "“How might we help local service providers manage their client transactions in one organized platform?”", lines: ["Communication", "Booking and scheduling", "Service updates", "Payment coordination"] },
  3: { num: "03", presenter: "Jeremiah", lead: "Fragmented local service transactions", title: "The Problem", lines: ["Providers advertise on Facebook, chat on Messenger, and follow up through SMS or calls", "Schedules and payment details are often tracked manually", "Important information can easily be missed"] },
  4: { num: "04", presenter: "Jeremiah", lead: "Messages are separated across channels", title: "Scattered Communication", lines: ["Inquiries may come from Messenger, SMS, calls, or social media", "Messages can get buried or forgotten", "Delayed responses can lead to lost opportunities"] },
  5: { num: "05", presenter: "Jeremiah", lead: "Manual handling creates friction", title: "Booking, Trust, and Transaction Problems", lines: ["Scheduling conflicts and forgotten appointments", "Unclear service status and payment details", "Limited proof of provider reputation or reliability"] },
  6: { num: "06", presenter: "Allen", lead: "What we developed", title: "Executive Summary", lines: ["A local service e-commerce marketplace", "The commodity is a service, not a physical product", "Providers list services, receive bookings, coordinate quotations, and build reputation"] },
  7: { num: "07", presenter: "Allen", lead: "Marketplace + service transaction process", title: "Business Concept", lines: ["Supports tutoring, photography, repair work, cleaning, design, and other local expertise", "Provider acts as the seller", "Client acts as the buyer"] },
  8: { num: "08", presenter: "Allen", lead: "The core promise", title: "Value Proposition", quote: "“Help clients find the right person for the job while helping providers turn their skills into visible and sellable service offerings.”", lines: ["Digital storefront for providers", "Less app-switching for clients", "More structured service transactions"] },
  9: { num: "09", presenter: "Lance", lead: "Services can be bought and sold digitally", title: "Why It Is E-Commerce", lines: ["The product being exchanged is a service", "The platform supports discovery, comparison, booking, quotation, payment coordination, completion, and review", "E-commerce marketplace concepts are applied to local services"] },
  10: { num: "10", presenter: "Lance", lead: "What the project aims to accomplish", title: "Objectives", lines: ["Create a dedicated service marketplace", "Make it easier to browse and compare providers", "Centralize the service transaction process", "Develop a sustainable revenue model"] },
  11: { num: "11", presenter: "Lance", lead: "Two-sided marketplace", title: "Target Market", lines: ["Independent service providers, freelancers, professionals, and small service businesses", "Tutors, photographers, repair technicians, designers, cleaners, and other skilled workers", "Clients such as individuals, groups, families, or businesses looking for local services"] },
  12: { num: "12", presenter: "Lance", lead: "Organizing existing behavior", title: "Problem Opportunity", lines: ["People already buy and sell local services every day", "Many transactions are still under-structured", "TrabaWho organizes this behavior through a digital marketplace"] },
  13: { num: "13", presenter: "Joshua", lead: "Built around the full service transaction", title: "Key Features", lines: ["Registration, profiles, portfolios, and service listings", "Search, filters, booking, scheduling, and in-app communication", "Service tracking, payment coordination, ratings, reviews, and admin tools"] },
  14: { num: "14", presenter: "Joshua", lead: "Turning skills into sellable offers", title: "Provider Profiles and Service Listings", lines: ["Display services, portfolio, credentials, and previous work", "Create service listings or packages", "Support fixed-price or quotation-based pricing"] },
  15: { num: "15", presenter: "Joshua", lead: "From browsing to actual transaction", title: "Search, Booking, and Scheduling", lines: ["Clients search and compare providers based on their needs", "Clients send booking requests and select available schedules", "A simple inquiry becomes a structured service transaction"] },
  16: { num: "16", presenter: "Joshua", lead: "Every chat has context", title: "Booking-Linked Communication", lines: ["In-app communication is connected to a specific booking", "Details, updates, and agreements stay attached to the job", "Reduces mixed-up conversations and lost information"] },
  17: { num: "17", presenter: "Joshua", lead: "Clear progress and records", title: "Service Status and Payment Coordination", lines: ["Track progress: pending, confirmed, scheduled, in progress, completed", "Record agreed prices, balances, and transaction notes", "Make payment coordination more organized"] },
  18: { num: "18", presenter: "Brent", lead: "How the marketplace works", title: "Transaction Flow", lines: ["Provider creates a profile and service listing", "Client browses the marketplace and selects a provider", "Client sends a booking request or selects a fixed-price package", "Provider confirms and may submit a quotation"] },
  19: { num: "19", presenter: "Brent", lead: "From agreement to review", title: "Transaction Flow Continued", quote: "“List → Discover → Book → Quote → Schedule → Service → Pay → Review”", lines: ["Both sides agree and proceed with scheduling, communication, and updates", "Provider marks the job completed, then client confirms completion", "Payment is coordinated and both sides may leave a review"] },
  20: { num: "20", presenter: "Brent", lead: "Flexible pricing with client approval", title: "Pricing and Quotations", lines: ["Fixed-price packages work for clear services", "Quotation-based pricing works for inspection-dependent services", "Revised quotations require client approval before becoming final"] },
  21: { num: "21", presenter: "Brent", lead: "Commercial sustainability", title: "Revenue Strategy", lines: ["Proposed 5% Transaction Coordination Fee", "Charged on the client’s downpayment for a confirmed booking.", "This allows TrabaWho to earn once a legitimate service transaction is secured through the platform."] },
  22: { num: "22", presenter: "Brent", lead: "Additional marketplace monetization", title: "Visibility and Premium Revenue", lines: ["Provider boosts or sponsored visibility", "Paid higher placement in relevant search results", "Future premium tools: analytics, storefront features, and business support"] },
  23: { num: "23", presenter: "Brent", lead: "Sample computation", title: "Revenue Example", lines: ["1,000 completed services × ₱1,500 average value", "Total service value: ₱1,500,000", "5% platform fee: approximately ₱75,000 revenue"] },
  24: { num: "24", presenter: "Neil", lead: "Existing alternatives", title: "Competitive Positioning", lines: ["LinkedIn, Fiverr, Upwork, Facebook, Messenger, and MyKuya", "We do not claim that selling services online is completely new", "TrabaWho differentiates through local focus and integrated service workflow"] },
  25: { num: "25", presenter: "Neil", lead: "Marketplace transaction, not just discovery", title: "Why TrabaWho Is Different", lines: ["LinkedIn focuses mainly on professional networking", "Fiverr and Upwork are strong for remote freelance work", "Facebook and Messenger provide discovery and chat, but service transactions remain unstructured", "TrabaWho organizes the complete local service transaction"] },
  26: { num: "26", presenter: "Neil", lead: "Initial marketplace experience", title: "Scope of Work", lines: ["Authentication, profiles, listings, search, booking, scheduling, communication, service tracking, payment coordination, reviews, and admin tools", "Future expansion: advanced financial infrastructure, large-scale dispute resolution, and external integrations"] },
  27: { num: "27", presenter: "Neil", lead: "NexusLink as platform owner", title: "Platform Management", lines: ["Operated by NexusLink IT Systems Corporation", "Platform admins handle verification, moderation, reports, maintenance, policies, and dispute review support", "Administrators focus on governance"] },
  28: { num: "28", presenter: "Neil", lead: "Users manage their own transactions", title: "Self-Service Operations", lines: ["Providers manage profiles, listings, pricing, availability, and booking responses", "Clients manage requests, quotation approvals, and transactions", "Admins do not control every transaction"] },
  29: { num: "29", presenter: "Neil", lead: "From validation to working marketplace", title: "Project Timeline", lines: ["Concept revision and requirement analysis", "System design", "Coding and development", "Testing, refinement, documentation, and review"] },
  30: { num: "30", presenter: "Neil", lead: "May trabaho? Who?", title: "Conclusion", lines: ["TrabaWho addresses fragmented local service transactions", "It brings service discovery, listings, booking, scheduling, communication, transaction coordination, and reviews into one organized environment", "Goal: make local service transactions more structured, transparent, and professional"] },
};

function shape(slide, ctx, x, y, w, h, fill, opts = {}) {
  return ctx.addShape(slide, {
    left: x,
    top: y,
    width: w,
    height: h,
    geometry: opts.geometry || "rect",
    fill,
    line: opts.line || ctx.line(),
    name: opts.name,
  });
}

function text(slide, ctx, value, x, y, w, h, opts = {}) {
  return ctx.addText(slide, {
    text: value,
    left: x,
    top: y,
    width: w,
    height: h,
    fontSize: opts.size || 22,
    color: opts.color || C.white,
    bold: Boolean(opts.bold),
    typeface: FONT,
    align: opts.align || "left",
    valign: opts.valign || "top",
    fill: opts.fill || "#00000000",
    line: opts.line || ctx.line(),
    insets: opts.insets || { left: 0, right: 0, top: 0, bottom: 0 },
    name: opts.name,
  });
}

function titleSize(value) {
  if (value.length > 38) return 38;
  if (value.length > 29) return 42;
  return 48;
}

async function addBrand(slide, ctx, d, dark = true) {
  await ctx.addImage(slide, {
    path: `${ctx.assetDir}/trabawho-logo.png`,
    left: 54,
    top: 25,
    width: 184,
    height: 51,
    fit: "contain",
    alt: "TrabaWho",
    name: "verified-trabawho-logo",
  });
  text(slide, ctx, "TrabaWho", 250, 681, 100, 8, { size: 1, color: dark ? C.bg : C.white, name: "source-brand-text" });
  text(slide, ctx, "NexusLink IT Systems Corporation", 844, 34, 288, 22, { size: 14, color: dark ? C.light : C.white, align: "right", valign: "middle", name: "company" });
  text(slide, ctx, d.num, 1160, 31, 64, 26, { size: 18, color: C.orange, bold: true, align: "right", valign: "middle", name: "page-number" });
}

function addFooter(slide, ctx, d) {
  shape(slide, ctx, 54, 662, 1170, 1, C.border, { name: "footer-rule" });
  text(slide, ctx, d.presenter, 54, 674, 180, 22, { size: 14, color: C.light, bold: true, valign: "middle", name: "presenter" });
}

function addTitle(slide, ctx, d, opts = {}) {
  const x = opts.x || 64;
  const y = opts.y || 104;
  const w = opts.w || 900;
  shape(slide, ctx, x, y + 4, 34, 4, C.orange, { name: "kicker-marker" });
  text(slide, ctx, d.lead, x + 48, y - 7, w - 48, 26, { size: 17, color: C.light, bold: true, valign: "middle", name: "kicker-label" });
  text(slide, ctx, d.title, x, y + 33, w, 67, { size: opts.titleSize || titleSize(d.title), bold: true, valign: "middle", name: "slide-title" });
}

async function base(slide, ctx, d, opts = {}) {
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, opts.bg || C.bg, { name: "background" });
  if (opts.photo) {
    await ctx.addImage(slide, { path: `${ctx.assetDir}/${opts.photo}`, left: opts.photoX || 0, top: 0, width: opts.photoW || ctx.W, height: ctx.H, fit: "cover", alt: "Workplace photography", name: "editorial-photo" });
    shape(slide, ctx, 0, 0, ctx.W, ctx.H, opts.overlay || "#0B1220C8", { name: "photo-overlay" });
  }
  await addBrand(slide, ctx, d, true);
  if (!opts.noTitle) addTitle(slide, ctx, d, opts.title || {});
  addFooter(slide, ctx, d);
}

function bullet(slide, ctx, value, x, y, w, opts = {}) {
  shape(slide, ctx, x, y + 8, 11, 11, opts.accent || C.blue, { geometry: "ellipse", name: `${opts.name || "bullet"}-marker` });
  text(slide, ctx, value, x + 28, y, w - 28, opts.h || 64, { size: opts.size || 20, color: opts.color || C.white, bold: Boolean(opts.bold), valign: "middle", name: `${opts.name || "bullet"}-text` });
}

function panel(slide, ctx, x, y, w, h, opts = {}) {
  return shape(slide, ctx, x, y, w, h, opts.fill || C.panel, { geometry: "roundRect", line: ctx.line(opts.border || C.border, opts.weight || 1), name: opts.name });
}

function sequenceLine(slide, ctx, x, y, w, count) {
  shape(slide, ctx, x, y + 17, w, 3, C.border, { name: "sequence-line" });
  const step = count > 1 ? w / (count - 1) : 0;
  for (let i = 0; i < count; i += 1) {
    shape(slide, ctx, x + i * step - 10, y + 8, 20, 20, i === count - 1 ? C.orange : C.blue, { geometry: "ellipse", name: `sequence-node-${i + 1}` });
  }
}

async function cover(presentation, ctx, d) {
  const slide = presentation.slides.add();
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, C.deep);
  await ctx.addImage(slide, { path: `${ctx.assetDir}/team.jpg`, left: 0, top: 0, width: ctx.W, height: ctx.H, fit: "cover", alt: "Team at work", name: "hero-photo" });
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, "#0B1220C2", { name: "hero-overlay" });
  shape(slide, ctx, 0, 0, 26, ctx.H, C.blue2, { name: "blue-edge" });
  shape(slide, ctx, 26, 0, 7, ctx.H, C.orange2, { name: "orange-edge" });
  await addBrand(slide, ctx, d, true);
  text(slide, ctx, d.title, 82, 140, 930, 145, { size: 60, bold: true, valign: "middle", name: "cover-title" });
  text(slide, ctx, d.lead, 86, 292, 720, 50, { size: 25, color: C.light, bold: true, valign: "middle", name: "cover-subtitle" });
  shape(slide, ctx, 86, 366, 720, 1, C.border);
  text(slide, ctx, d.lines[0], 86, 394, 760, 42, { size: 22, color: C.white, bold: true, valign: "middle", name: "cover-line-1" });
  text(slide, ctx, d.lines[1], 86, 449, 760, 42, { size: 22, color: C.light, valign: "middle", name: "cover-line-2" });
  text(slide, ctx, d.presenter, 86, 652, 180, 25, { size: 15, color: C.white, bold: true, valign: "middle", name: "presenter" });
  return slide;
}

async function radialQuestion(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 311, 269, 658, 150, { fill: C.panel2, border: C.blue, weight: 2, name: "question-panel" });
  text(slide, ctx, d.quote, 350, 292, 580, 104, { size: 25, bold: true, align: "center", valign: "middle", name: "question" });
  const positions = [[78, 261], [78, 457], [966, 261], [966, 457]];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, positions[i][0], positions[i][1], 236, 92, { fill: i % 2 ? C.panel2 : C.panel, border: i < 2 ? C.blue2 : C.orange2, name: `channel-${i + 1}` });
    text(slide, ctx, line, positions[i][0] + 18, positions[i][1] + 18, 200, 56, { size: 18, bold: true, align: "center", valign: "middle", name: `channel-text-${i + 1}` });
  });
  shape(slide, ctx, 314, 307, 47, 2, C.blue2);
  shape(slide, ctx, 920, 307, 47, 2, C.orange2);
  shape(slide, ctx, 314, 502, 78, 2, C.blue2);
  shape(slide, ctx, 889, 502, 78, 2, C.orange2);
  return slide;
}

async function problemBands(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const ys = [244, 374, 504];
  d.lines.forEach((line, i) => {
    const x = 76 + i * 52;
    const w = 1060 - i * 104;
    panel(slide, ctx, x, ys[i], w, 94, { fill: i === 1 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.border, name: `problem-band-${i + 1}` });
    shape(slide, ctx, x, ys[i], 9, 94, i === 2 ? C.orange : C.blue, { name: `problem-accent-${i + 1}` });
    text(slide, ctx, line, x + 38, ys[i] + 16, w - 72, 62, { size: 21, bold: i === 2, valign: "middle", name: `problem-text-${i + 1}` });
  });
  return slide;
}

async function communicationScatter(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  shape(slide, ctx, 637, 244, 4, 338, C.border, { name: "split-line" });
  const positions = [[74, 262, 470], [736, 300, 430], [164, 476, 492]];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, positions[i][0], positions[i][1], positions[i][2], 104, { fill: i === 2 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.blue2, name: `scatter-${i + 1}` });
    bullet(slide, ctx, line, positions[i][0] + 24, positions[i][1] + 20, positions[i][2] - 48, { size: 20, h: 64, accent: i === 2 ? C.orange : C.blue, name: `scatter-${i + 1}` });
  });
  return slide;
}

async function problemSequence(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  sequenceLine(slide, ctx, 132, 288, 1016, 3);
  const xs = [64, 438, 812];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, xs[i], 342, 340, 190, { fill: i === 2 ? "#2D2630" : C.panel, border: i === 2 ? C.orange2 : C.border, name: `risk-${i + 1}` });
    shape(slide, ctx, xs[i] + 28, 368, 54, 7, i === 2 ? C.orange : C.blue, { name: `risk-accent-${i + 1}` });
    text(slide, ctx, line, xs[i] + 28, 397, 284, 104, { size: 21, bold: true, valign: "middle", name: `risk-text-${i + 1}` });
  });
  return slide;
}

async function editorialPhoto(presentation, ctx, d, photo) {
  const slide = presentation.slides.add();
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, C.bg);
  await ctx.addImage(slide, { path: `${ctx.assetDir}/${photo}`, left: 766, top: 0, width: 514, height: ctx.H, fit: "cover", alt: "Local service work", name: "right-photo" });
  shape(slide, ctx, 716, 0, 166, ctx.H, "#111827E8", { name: "photo-gradient-mask" });
  await addBrand(slide, ctx, d, true);
  addFooter(slide, ctx, d);
  addTitle(slide, ctx, d, { x: 64, y: 114, w: 670 });
  d.lines.forEach((line, i) => bullet(slide, ctx, line, 72, 276 + i * 100, 622, { size: 21, h: 76, accent: i === 1 ? C.orange : C.blue, bold: i === 0, name: `editorial-line-${i + 1}` }));
  return slide;
}

async function marketplaceExchange(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 330, 255, 620, 108, { fill: C.panel2, border: C.border, name: "market-context" });
  text(slide, ctx, d.lines[0], 364, 274, 552, 68, { size: 21, align: "center", valign: "middle", name: "market-context-text" });
  panel(slide, ctx, 84, 421, 450, 126, { fill: C.panel, border: C.blue2, weight: 2, name: "seller-node" });
  panel(slide, ctx, 746, 421, 450, 126, { fill: C.panel, border: C.orange2, weight: 2, name: "buyer-node" });
  text(slide, ctx, d.lines[1], 118, 448, 382, 72, { size: 23, bold: true, align: "center", valign: "middle", name: "seller-text" });
  text(slide, ctx, d.lines[2], 780, 448, 382, 72, { size: 23, bold: true, align: "center", valign: "middle", name: "buyer-text" });
  shape(slide, ctx, 534, 482, 212, 4, C.border, { name: "exchange-line" });
  shape(slide, ctx, 621, 466, 38, 38, C.blue, { geometry: "ellipse", name: "exchange-node" });
  return slide;
}

async function valueQuote(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 66, 245, 700, 250, { fill: C.panel2, border: C.blue2, weight: 2, name: "value-quote" });
  shape(slide, ctx, 94, 276, 8, 183, C.orange);
  text(slide, ctx, d.quote, 132, 276, 590, 184, { size: 27, bold: true, valign: "middle", name: "quote-text" });
  d.lines.forEach((line, i) => {
    const y = 254 + i * 106;
    panel(slide, ctx, 820, y, 392, 84, { fill: i === 2 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.border, name: `benefit-${i + 1}` });
    text(slide, ctx, line, 846, y + 14, 340, 56, { size: 19, bold: true, valign: "middle", name: `benefit-text-${i + 1}` });
  });
  return slide;
}

async function commerceLifecycle(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 82, 248, 1116, 88, { fill: C.panel2, border: C.blue2, name: "service-object" });
  text(slide, ctx, d.lines[0], 116, 266, 1048, 52, { size: 22, bold: true, align: "center", valign: "middle", name: "service-object-text" });
  sequenceLine(slide, ctx, 153, 399, 974, 7);
  panel(slide, ctx, 82, 454, 1116, 88, { fill: C.panel, border: C.border, name: "commerce-process" });
  text(slide, ctx, d.lines[1], 116, 468, 1048, 60, { size: 20, align: "center", valign: "middle", name: "commerce-process-text" });
  text(slide, ctx, d.lines[2], 164, 567, 952, 48, { size: 19, color: C.light, bold: true, align: "center", valign: "middle", name: "commerce-close" });
  return slide;
}

async function objectiveSteps(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const widths = [255, 255, 255, 255];
  d.lines.forEach((line, i) => {
    const x = 70 + i * 294;
    const y = 520 - i * 72;
    panel(slide, ctx, x, y, widths[i], 104, { fill: i === 3 ? C.panel2 : C.panel, border: i === 3 ? C.orange2 : C.blue2, name: `objective-${i + 1}` });
    text(slide, ctx, line, x + 22, y + 18, widths[i] - 44, 68, { size: 18, bold: true, align: "center", valign: "middle", name: `objective-text-${i + 1}` });
    if (i < 3) shape(slide, ctx, x + 255, y + 50, 39, 3, C.border, { name: `objective-connector-${i + 1}` });
  });
  return slide;
}

async function targetMarket(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 76, 246, 526, 306, { fill: C.panel, border: C.blue2, weight: 2, name: "provider-market" });
  panel(slide, ctx, 678, 246, 526, 306, { fill: C.panel, border: C.orange2, weight: 2, name: "client-market" });
  text(slide, ctx, d.lines[0], 116, 279, 446, 92, { size: 23, bold: true, valign: "middle", name: "provider-primary" });
  shape(slide, ctx, 116, 390, 110, 5, C.blue);
  text(slide, ctx, d.lines[1], 116, 416, 446, 104, { size: 19, color: C.light, valign: "middle", name: "provider-examples" });
  text(slide, ctx, d.lines[2], 718, 312, 446, 166, { size: 23, bold: true, valign: "middle", name: "client-primary" });
  shape(slide, ctx, 613, 382, 54, 34, C.panel2, { geometry: "roundRect", line: ctx.line(C.border, 1), name: "market-bridge" });
  return slide;
}

async function behaviorBridge(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d, { photo: "workshop.jpg", overlay: "#0B1220DD" });
  panel(slide, ctx, 72, 254, 1136, 246, { fill: "#111827D8", border: C.border, name: "behavior-panel" });
  const xs = [102, 456, 810];
  d.lines.forEach((line, i) => {
    shape(slide, ctx, xs[i], 290, 282, 6, i === 2 ? C.orange : C.blue, { name: `behavior-accent-${i + 1}` });
    text(slide, ctx, line, xs[i], 322, 282, 130, { size: 21, bold: i === 2, align: "center", valign: "middle", name: `behavior-text-${i + 1}` });
  });
  return slide;
}

async function featureSystem(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 424, 310, 432, 112, { fill: C.panel2, border: C.orange2, weight: 2, name: "feature-core" });
  text(slide, ctx, d.lines[1], 456, 330, 368, 72, { size: 20, bold: true, align: "center", valign: "middle", name: "feature-core-text" });
  panel(slide, ctx, 78, 270, 296, 190, { fill: C.panel, border: C.blue2, name: "feature-left" });
  text(slide, ctx, d.lines[0], 104, 300, 244, 130, { size: 20, bold: true, align: "center", valign: "middle", name: "feature-left-text" });
  panel(slide, ctx, 906, 270, 296, 190, { fill: C.panel, border: C.blue2, name: "feature-right" });
  text(slide, ctx, d.lines[2], 932, 300, 244, 130, { size: 20, bold: true, align: "center", valign: "middle", name: "feature-right-text" });
  shape(slide, ctx, 374, 363, 50, 3, C.border);
  shape(slide, ctx, 856, 363, 50, 3, C.border);
  return slide;
}

async function providerListing(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 76, 244, 1128, 354, { fill: C.panel, border: C.border, name: "listing-frame" });
  shape(slide, ctx, 76, 244, 1128, 58, C.panel2, { name: "listing-topbar" });
  shape(slide, ctx, 106, 261, 24, 24, C.blue, { geometry: "ellipse", name: "listing-dot-blue" });
  shape(slide, ctx, 141, 261, 24, 24, C.orange, { geometry: "ellipse", name: "listing-dot-orange" });
  text(slide, ctx, d.lines[0], 112, 328, 500, 114, { size: 23, bold: true, valign: "middle", name: "listing-profile" });
  shape(slide, ctx, 644, 323, 1, 214, C.border);
  text(slide, ctx, d.lines[1], 684, 326, 454, 78, { size: 21, bold: true, valign: "middle", name: "listing-services" });
  panel(slide, ctx, 684, 439, 454, 83, { fill: C.panel2, border: C.blue2, name: "listing-pricing" });
  text(slide, ctx, d.lines[2], 710, 455, 402, 50, { size: 19, bold: true, align: "center", valign: "middle", name: "listing-pricing-text" });
  return slide;
}

async function discoveryPath(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  sequenceLine(slide, ctx, 168, 317, 944, 3);
  const xs = [72, 461, 850];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, xs[i], 378, 356, 158, { fill: i === 2 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.blue2, name: `discovery-${i + 1}` });
    text(slide, ctx, line, xs[i] + 26, 401, 304, 110, { size: 20, bold: true, align: "center", valign: "middle", name: `discovery-text-${i + 1}` });
  });
  return slide;
}

async function linkedCommunication(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 108, 254, 1064, 292, { fill: C.panel, border: C.border, name: "conversation-frame" });
  panel(slide, ctx, 142, 286, 586, 74, { fill: C.panel2, border: C.blue2, name: "message-one" });
  text(slide, ctx, d.lines[0], 166, 300, 538, 46, { size: 19, bold: true, valign: "middle", name: "message-one-text" });
  panel(slide, ctx, 550, 384, 586, 74, { fill: "#2D2630", border: C.orange2, name: "message-two" });
  text(slide, ctx, d.lines[1], 574, 398, 538, 46, { size: 19, bold: true, valign: "middle", name: "message-two-text" });
  text(slide, ctx, d.lines[2], 216, 485, 848, 42, { size: 20, color: C.light, bold: true, align: "center", valign: "middle", name: "conversation-result" });
  return slide;
}

async function statusPayment(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 70, 250, 1140, 132, { fill: C.panel2, border: C.blue2, name: "status-lane" });
  text(slide, ctx, d.lines[0], 104, 270, 1072, 88, { size: 23, bold: true, align: "center", valign: "middle", name: "status-text" });
  sequenceLine(slide, ctx, 162, 412, 956, 5);
  panel(slide, ctx, 70, 468, 540, 102, { fill: C.panel, border: C.border, name: "record-lane" });
  panel(slide, ctx, 670, 468, 540, 102, { fill: C.panel, border: C.orange2, name: "coordination-lane" });
  text(slide, ctx, d.lines[1], 98, 486, 484, 66, { size: 20, bold: true, align: "center", valign: "middle", name: "record-text" });
  text(slide, ctx, d.lines[2], 698, 486, 484, 66, { size: 20, bold: true, align: "center", valign: "middle", name: "coordination-text" });
  return slide;
}

async function transactionFlow(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const xs = [64, 355, 646, 937];
  const ys = [276, 326, 376, 426];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, xs[i], ys[i], 262, 138, { fill: i === 3 ? C.panel2 : C.panel, border: i === 3 ? C.orange2 : C.blue2, name: `flow-step-${i + 1}` });
    text(slide, ctx, line, xs[i] + 22, ys[i] + 22, 218, 94, { size: 18, bold: true, align: "center", valign: "middle", name: `flow-text-${i + 1}` });
    if (i < 3) shape(slide, ctx, xs[i] + 262, ys[i] + 67, 29, 3, C.border, { name: `flow-connector-${i + 1}` });
  });
  return slide;
}

async function flowContinued(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 72, 242, 1136, 112, { fill: C.panel2, border: C.orange2, weight: 2, name: "flow-ribbon" });
  text(slide, ctx, d.quote, 104, 264, 1072, 68, { size: 27, bold: true, align: "center", valign: "middle", name: "flow-ribbon-text" });
  d.lines.forEach((line, i) => bullet(slide, ctx, line, 126, 392 + i * 72, 1030, { size: 20, h: 54, accent: i === 2 ? C.orange : C.blue, name: `flow-result-${i + 1}` }));
  return slide;
}

async function pricingComparison(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 74, 255, 520, 210, { fill: C.panel, border: C.blue2, weight: 2, name: "fixed-price" });
  panel(slide, ctx, 686, 255, 520, 210, { fill: C.panel, border: C.orange2, weight: 2, name: "quotation" });
  text(slide, ctx, d.lines[0], 112, 300, 444, 120, { size: 25, bold: true, align: "center", valign: "middle", name: "fixed-price-text" });
  text(slide, ctx, d.lines[1], 724, 300, 444, 120, { size: 25, bold: true, align: "center", valign: "middle", name: "quotation-text" });
  panel(slide, ctx, 244, 506, 792, 86, { fill: C.panel2, border: C.border, name: "approval-rule" });
  text(slide, ctx, d.lines[2], 276, 524, 728, 50, { size: 21, bold: true, align: "center", valign: "middle", name: "approval-rule-text" });
  return slide;
}

async function feeMechanism(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 64, 250, 1144, 184, { fill: C.panel2, border: C.orange2, weight: 2, name: "fee-callout" });
  text(slide, ctx, d.lines[0], 98, 278, 500, 126, { size: 34, bold: true, align: "center", valign: "middle", name: "fee-callout-text" });
  shape(slide, ctx, 630, 278, 1, 128, C.border, { name: "fee-divider" });
  text(slide, ctx, d.lines[1], 672, 294, 492, 94, { size: 22, color: C.light, align: "center", valign: "middle", name: "fee-basis" });
  panel(slide, ctx, 64, 484, 1144, 84, { fill: C.panel, border: C.blue2, name: "fee-result" });
  text(slide, ctx, d.lines[2], 92, 503, 1088, 46, { size: 18, bold: true, align: "center", valign: "middle", name: "fee-result-text" });
  return slide;
}

async function revenueLadder(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const dims = [[84, 444, 344, 118], [468, 354, 344, 208], [852, 264, 344, 298]];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, dims[i][0], dims[i][1], dims[i][2], dims[i][3], { fill: i === 2 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.blue2, name: `revenue-step-${i + 1}` });
    text(slide, ctx, line, dims[i][0] + 26, dims[i][1] + 24, dims[i][2] - 52, dims[i][3] - 48, { size: i === 2 ? 22 : 20, bold: true, align: "center", valign: "middle", name: `revenue-text-${i + 1}` });
  });
  return slide;
}

async function revenueExample(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  text(slide, ctx, d.lines[0], 86, 248, 1108, 80, { size: 31, bold: true, align: "center", valign: "middle", name: "revenue-formula" });
  shape(slide, ctx, 176, 351, 928, 2, C.border);
  panel(slide, ctx, 90, 390, 516, 150, { fill: C.panel, border: C.blue2, name: "service-value" });
  panel(slide, ctx, 674, 390, 516, 150, { fill: C.panel2, border: C.orange2, weight: 2, name: "platform-fee" });
  text(slide, ctx, d.lines[1], 126, 421, 444, 88, { size: 27, bold: true, align: "center", valign: "middle", name: "service-value-text" });
  text(slide, ctx, d.lines[2], 710, 421, 444, 88, { size: 27, bold: true, align: "center", valign: "middle", name: "platform-fee-text" });
  return slide;
}

async function competitorLandscape(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 70, 248, 1140, 86, { fill: C.panel2, border: C.border, name: "alternatives" });
  text(slide, ctx, d.lines[0], 104, 266, 1072, 50, { size: 23, bold: true, align: "center", valign: "middle", name: "alternatives-text" });
  panel(slide, ctx, 70, 372, 530, 162, { fill: C.panel, border: C.border, name: "competitive-context" });
  panel(slide, ctx, 680, 372, 530, 162, { fill: C.panel, border: C.orange2, weight: 2, name: "competitive-difference" });
  text(slide, ctx, d.lines[1], 102, 398, 466, 110, { size: 21, align: "center", valign: "middle", name: "competitive-context-text" });
  text(slide, ctx, d.lines[2], 712, 398, 466, 110, { size: 21, bold: true, align: "center", valign: "middle", name: "competitive-difference-text" });
  return slide;
}

async function differenceStack(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const ys = [240, 329, 418, 517];
  d.lines.forEach((line, i) => {
    const x = 74 + (i % 2) * 68;
    const w = 1132 - (i % 2) * 136;
    panel(slide, ctx, x, ys[i], w, 72, { fill: i === 3 ? C.panel2 : C.panel, border: i === 3 ? C.orange2 : C.border, weight: i === 3 ? 2 : 1, name: `difference-${i + 1}` });
    text(slide, ctx, line, x + 28, ys[i] + 12, w - 56, 48, { size: 19, bold: i === 3, valign: "middle", name: `difference-text-${i + 1}` });
  });
  return slide;
}

async function scopeBands(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 70, 248, 1140, 176, { fill: C.panel2, border: C.blue2, name: "initial-scope" });
  text(slide, ctx, d.lines[0], 108, 276, 1064, 120, { size: 23, bold: true, align: "center", valign: "middle", name: "initial-scope-text" });
  panel(slide, ctx, 180, 472, 920, 106, { fill: C.panel, border: C.orange2, name: "future-scope" });
  text(slide, ctx, d.lines[1], 216, 492, 848, 66, { size: 20, color: C.light, bold: true, align: "center", valign: "middle", name: "future-scope-text" });
  return slide;
}

async function governanceLayers(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  const widths = [1080, 880, 680];
  const xs = [100, 200, 300];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, xs[i], 250 + i * 108, widths[i], 82, { fill: i === 2 ? C.panel2 : C.panel, border: i === 2 ? C.orange2 : C.blue2, name: `governance-${i + 1}` });
    text(slide, ctx, line, xs[i] + 28, 264 + i * 108, widths[i] - 56, 54, { size: i === 1 ? 19 : 21, bold: true, align: "center", valign: "middle", name: `governance-text-${i + 1}` });
  });
  return slide;
}

async function selfService(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  panel(slide, ctx, 72, 256, 540, 216, { fill: C.panel, border: C.blue2, weight: 2, name: "provider-ops" });
  panel(slide, ctx, 668, 256, 540, 216, { fill: C.panel, border: C.orange2, weight: 2, name: "client-ops" });
  text(slide, ctx, d.lines[0], 108, 296, 468, 136, { size: 23, bold: true, align: "center", valign: "middle", name: "provider-ops-text" });
  text(slide, ctx, d.lines[1], 704, 296, 468, 136, { size: 23, bold: true, align: "center", valign: "middle", name: "client-ops-text" });
  text(slide, ctx, d.lines[2], 190, 514, 900, 54, { size: 22, color: C.light, bold: true, align: "center", valign: "middle", name: "admin-boundary" });
  return slide;
}

async function timeline(presentation, ctx, d) {
  const slide = presentation.slides.add();
  await base(slide, ctx, d);
  sequenceLine(slide, ctx, 142, 334, 996, 4);
  const xs = [54, 348, 642, 936];
  d.lines.forEach((line, i) => {
    panel(slide, ctx, xs[i], i % 2 === 0 ? 388 : 438, 290, 118, { fill: i === 3 ? C.panel2 : C.panel, border: i === 3 ? C.orange2 : C.border, name: `timeline-stage-${i + 1}` });
    text(slide, ctx, line, xs[i] + 22, (i % 2 === 0 ? 388 : 438) + 20, 246, 78, { size: 19, bold: true, align: "center", valign: "middle", name: `timeline-text-${i + 1}` });
  });
  return slide;
}

async function conclusion(presentation, ctx, d) {
  const slide = presentation.slides.add();
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, C.deep);
  await ctx.addImage(slide, { path: `${ctx.assetDir}/meeting.jpg`, left: 620, top: 0, width: 660, height: ctx.H, fit: "cover", alt: "People coordinating work", name: "closing-photo" });
  shape(slide, ctx, 0, 0, ctx.W, ctx.H, "#0B1220B8", { name: "closing-overlay" });
  shape(slide, ctx, 0, 0, 700, ctx.H, "#0B1220E8", { name: "closing-copy-field" });
  await addBrand(slide, ctx, d, true);
  addFooter(slide, ctx, d);
  addTitle(slide, ctx, d, { x: 64, y: 112, w: 560, titleSize: 52 });
  d.lines.forEach((line, i) => bullet(slide, ctx, line, 70, 269 + i * 106, 540, { size: i === 1 ? 19 : 21, h: 86, accent: i === 2 ? C.orange : C.blue, bold: i === 2, name: `closing-line-${i + 1}` }));
  return slide;
}

export async function buildSlide(n, presentation, ctx) {
  const d = CONTENT[n];
  if (!d) throw new Error(`Missing source content for slide ${n}`);
  switch (n) {
    case 1: return cover(presentation, ctx, d);
    case 2: return radialQuestion(presentation, ctx, d);
    case 3: return problemBands(presentation, ctx, d);
    case 4: return communicationScatter(presentation, ctx, d);
    case 5: return problemSequence(presentation, ctx, d);
    case 6: return editorialPhoto(presentation, ctx, d, "repair.jpg");
    case 7: return marketplaceExchange(presentation, ctx, d);
    case 8: return valueQuote(presentation, ctx, d);
    case 9: return commerceLifecycle(presentation, ctx, d);
    case 10: return objectiveSteps(presentation, ctx, d);
    case 11: return targetMarket(presentation, ctx, d);
    case 12: return behaviorBridge(presentation, ctx, d);
    case 13: return featureSystem(presentation, ctx, d);
    case 14: return providerListing(presentation, ctx, d);
    case 15: return discoveryPath(presentation, ctx, d);
    case 16: return linkedCommunication(presentation, ctx, d);
    case 17: return statusPayment(presentation, ctx, d);
    case 18: return transactionFlow(presentation, ctx, d);
    case 19: return flowContinued(presentation, ctx, d);
    case 20: return pricingComparison(presentation, ctx, d);
    case 21: return feeMechanism(presentation, ctx, d);
    case 22: return revenueLadder(presentation, ctx, d);
    case 23: return revenueExample(presentation, ctx, d);
    case 24: return competitorLandscape(presentation, ctx, d);
    case 25: return differenceStack(presentation, ctx, d);
    case 26: return scopeBands(presentation, ctx, d);
    case 27: return governanceLayers(presentation, ctx, d);
    case 28: return selfService(presentation, ctx, d);
    case 29: return timeline(presentation, ctx, d);
    case 30: return conclusion(presentation, ctx, d);
    default: throw new Error(`No layout for slide ${n}`);
  }
}
