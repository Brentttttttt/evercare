# EverCare onboarding artwork

These four companion illustrations were generated with the built-in image
generation tool on 2026-09-24. Existing EverCare artwork was supplied as visual
style/character reference, not replaced or edited:

- `assets/images/dashboard_care.png`
- `assets/images/medication_support.png`
- `assets/images/appointment_card_v2.png`

## Integration

| Screen | New bundled asset |
| --- | --- |
| Welcome / care at home | `assets/images/onboarding/care_at_home.png` |
| Manage Your Daily Care | `assets/images/onboarding/daily_care.png` |
| Stay Connected with Family | `assets/images/onboarding/connected_care.png` |
| Feel Safer Every Day | `assets/images/onboarding/safety_support.png` |

Welcome and onboarding reuse the existing `AuthBackground` and its
`assets/images/auth_background.png` behind accessible Flutter text and controls.
Illustrations are contained rather than cropped so faces and care objects stay
visible. The illustrations are decorative; all onboarding meaning remains in
the screen's actual text. The bundled images work offline.

The nested `assets/images/onboarding/` directory is declared in `pubspec.yaml`;
the parent images directory does not automatically bundle nested directories.
Preserve the originals if later commissioning replacement artwork.

## Final generation prompts

### care_at_home

```text
Use case: illustration-story.
Asset type: one landscape 1536x1024 watercolor vignette for an EverCare mobile onboarding slide, an illustration only, NOT a UI mockup.
Input images: all supplied images are STYLE AND CHARACTER REFERENCES from EverCare's existing dashboard, appointments and medication artwork. Create a NEW companion scene; do not reproduce the reference composition or change those source files.
Style invariants: closely match the references' hand-painted watercolor on textured paper, soft bleeding pigment edges, subtle pencil-like detail, natural warm Filipino family character design and expressions. Elderly woman with softly waved short silver hair, warm skin and a sage/cream blouse, supported by a younger dark-haired woman in muted sage or dusty blue. Soft pastel greens, cream and muted warm wood. Gentle, premium, comforting rather than cartoonish. Sparse home details and plants. Center the people/important objects with generous margins; irregular watercolor edges feather into an almost white warm paper background. Keep all faces, hands and main objects fully inside frame.
Avoid: flat vector art, glossy 3D, harsh outlines, photorealism, dramatic emergencies, distress, saturated digital colors, busy background, collage, UI, panels, letters, numbers, text, logos or watermarks.
Scene: Health support that feels close to home. The elderly woman and her adult daughter/caregiver sit together on a cream sofa in a bright calm home. They exchange a warm reassuring smile, the younger woman's hand resting supportively near the elder's hand. Small potted greenery and a soft sage cushion suggest a cared-for home. No medical devices needed, focus on dignity, companionship and welcoming care.
```

### daily_care

```text
Use case: illustration-story.
Asset type: one landscape 1536x1024 watercolor vignette for an EverCare mobile onboarding slide, an illustration only, NOT a UI mockup.
Input images: all supplied images are STYLE AND CHARACTER REFERENCES from EverCare's existing dashboard, appointments and medication artwork. Create a NEW companion scene; do not reproduce the reference composition or change those source files.
Style invariants: closely match the references' hand-painted watercolor on textured paper, soft bleeding pigment edges, subtle pencil-like detail, natural warm Filipino family character design and expressions. Elderly woman with softly waved short silver hair, warm skin and a sage/cream blouse, supported by a younger dark-haired woman in muted sage or dusty blue. Soft pastel greens, cream and muted warm wood. Gentle, premium, comforting rather than cartoonish. Sparse home details and plants. Center the people/important objects with generous margins; irregular watercolor edges feather into an almost white warm paper background. Keep all faces, hands and main objects fully inside frame.
Avoid: flat vector art, glossy 3D, harsh outlines, photorealism, dramatic emergencies, distress, saturated digital colors, busy background, collage, UI, panels, letters, numbers, text, logos or watermarks.
Scene: Manage daily care. The elderly woman and younger caregiver calmly review their care routine at a light wooden table. On the table: a small closed pale pill organizer, a blood-pressure monitor with no readable digits, and a simple paper calendar/checklist with blank squares. Caregiver gently points to the paper while the elder participates confidently. Sparse objects, natural hands, no loose medicine ingestion, not an instructional medical diagram.
```

### connected_care

```text
Use case: illustration-story.
Asset type: one landscape 1536x1024 watercolor vignette for an EverCare mobile onboarding slide, an illustration only, NOT a UI mockup.
Input images: all supplied images are STYLE AND CHARACTER REFERENCES from EverCare's existing dashboard, appointments and medication artwork. Create a NEW companion scene; do not reproduce the reference composition or change those source files.
Style invariants: closely match the references' hand-painted watercolor on textured paper, soft bleeding pigment edges, subtle pencil-like detail, natural warm Filipino family character design and expressions. Elderly woman with softly waved short silver hair, warm skin and a sage/cream blouse, supported by a younger dark-haired woman in muted sage or dusty blue. Soft pastel greens, cream and muted warm wood. Gentle, premium, comforting rather than cartoonish. Sparse home details and plants. Center the people/important objects with generous margins; irregular watercolor edges feather into an almost white warm paper background. Keep all faces, hands and main objects fully inside frame.
Avoid: flat vector art, glossy 3D, harsh outlines, photorealism, dramatic emergencies, distress, saturated digital colors, busy background, collage, UI, panels, letters, numbers, text, logos or watermarks.
Scene: Stay connected with family. The elderly woman, younger caregiver/daughter and an adult son sit close together in a warm home, sharing a relaxed supportive conversation. One person holds a small phone facing inward with its screen not visible. The elder is an active participant at the center. Warm smiles, natural hands, cozy muted green surroundings. The image communicates trust and a real caring family, not technology.
```

### safety_support

```text
Use case: illustration-story.
Asset type: one landscape 1536x1024 watercolor vignette for an EverCare mobile onboarding slide, an illustration only, NOT a UI mockup.
Input images: all supplied images are STYLE AND CHARACTER REFERENCES from EverCare's existing dashboard, appointments and medication artwork. Create a NEW companion scene; do not reproduce the reference composition or change those source files.
Style invariants: closely match the references' hand-painted watercolor on textured paper, soft bleeding pigment edges, subtle pencil-like detail, natural warm Filipino family character design and expressions. Elderly woman with softly waved short silver hair, warm skin and a sage/cream blouse, supported by a younger dark-haired woman in muted sage or dusty blue. Soft pastel greens, cream and muted warm wood. Gentle, premium, comforting rather than cartoonish. Sparse home details and plants. Center the people/important objects with generous margins; irregular watercolor edges feather into an almost white warm paper background. Keep all faces, hands and main objects fully inside frame.
Avoid: flat vector art, glossy 3D, harsh outlines, photorealism, dramatic emergencies, distress, saturated digital colors, busy background, collage, UI, panels, letters, numbers, text, logos or watermarks.
Scene: Feel safer every day. The elderly woman is safe and relaxed at home with her younger caregiver nearby. They calmly prepare a small cream first-aid pouch with a subtle muted-green plus emblem, a phone with screen facing down, and a simple emergency-contact card with no legible writing on a side table. Reassuring warm expressions, no accident or alarm. A safe prepared home, not an emergency unfolding. Keep props few and secondary to the caring relationship.
```

