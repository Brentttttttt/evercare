import '../models/care_book_chapter.dart';

abstract final class CareBookData {
  static const chapters = [
    CareBookChapter(
      number: 1,
      title: 'Getting Started as a Caregiver',
      readingTime: '3 min read',
      iconName: 'start',
      paragraphs: [
        'Caregiving can mean helping with meals, medicines, transportation, appointments, household tasks, personal care, companionship, and health monitoring.',
        'Begin with a calm conversation about the older adult’s preferences. Agree on the kind of support that feels helpful and respectful.',
      ],
      tips: [
        'Write down the most important daily tasks.',
        'Keep familiar routines whenever possible.',
      ],
      highlight:
          'Start by identifying which tasks the older adult can do independently and where assistance is truly needed.',
    ),
    CareBookChapter(
      number: 2,
      title: 'Understanding the Older Adult’s Needs',
      readingTime: '3 min read',
      iconName: 'needs',
      paragraphs: [
        'Every older adult has different health, emotional, social, cultural, and personal needs. Needs may also change over time.',
        'Ask respectful questions, listen carefully, and include the older adult in decisions that affect daily life and care.',
      ],
      checklist: [
        'Health and mobility needs',
        'Emotional and social support',
        'Personal routines and preferences',
      ],
      highlight: 'Support independence whenever it is safe and possible.',
    ),
    CareBookChapter(
      number: 3,
      title: 'Creating a Daily Care Routine',
      readingTime: '4 min read',
      iconName: 'routine',
      paragraphs: [
        'A predictable routine can make meals, medicine, hygiene, movement, rest, and sleep easier to remember and less stressful.',
        'Keep the schedule flexible enough for energy levels, appointments, and personal choices.',
      ],
      checklist: [
        'Morning medicine and breakfast',
        'Blood-pressure measurement',
        'Light activity',
        'Lunch and hydration',
        'Afternoon rest',
        'Evening medicine',
        'Bedtime preparation',
      ],
    ),
    CareBookChapter(
      number: 4,
      title: 'Medication and Appointment Support',
      readingTime: '4 min read',
      iconName: 'medicine',
      paragraphs: [
        'Good organization helps caregivers follow the prescribed schedule and prepare useful information for medical visits.',
      ],
      checklist: [
        'Keep an updated medicine list',
        'Follow the prescribed schedule',
        'Use clear reminders',
        'Record missed medicines',
        'Prepare questions before appointments',
        'Bring important health records',
      ],
      disclaimer:
          'Do not change a medicine or dosage without instructions from a qualified healthcare professional.',
    ),
    CareBookChapter(
      number: 5,
      title: 'Healthy Meals and Hydration',
      readingTime: '3 min read',
      iconName: 'meals',
      paragraphs: [
        'Regular meals, balanced food choices, and enough water support strength and well-being. Notice meaningful changes in appetite or drinking habits.',
      ],
      tips: [
        'Offer familiar foods in manageable portions.',
        'Make drinks easy to reach and offer small amounts regularly throughout the day.',
      ],
    ),
    CareBookChapter(
      number: 6,
      title: 'Safe Movement and Fall Prevention',
      readingTime: '4 min read',
      iconName: 'movement',
      paragraphs: [
        'A safer home supports confidence and movement. Review frequently used spaces and make small changes before problems occur.',
      ],
      checklist: [
        'Keep pathways clear',
        'Improve lighting',
        'Remove loose rugs',
        'Use stable footwear',
        'Keep common items within reach',
        'Encourage safe movement',
        'Ask for guidance when mobility changes',
      ],
    ),
    CareBookChapter(
      number: 7,
      title: 'Communication and Emotional Support',
      readingTime: '3 min read',
      iconName: 'communication',
      paragraphs: [
        'Patience, active listening, clear instructions, familiar routines, and meaningful social interaction can help an older adult feel secure and respected.',
      ],
      tips: [
        'Allow enough time for answers.',
        'Use calm, short, and respectful sentences.',
      ],
      highlight: 'Speak with the older adult, not only about them.',
    ),
    CareBookChapter(
      number: 8,
      title: 'Preparing for Medical Visits',
      readingTime: '3 min read',
      iconName: 'visit',
      paragraphs: [
        'Preparing information before a visit makes it easier to describe changes, ask questions, and remember the healthcare provider’s instructions.',
      ],
      checklist: [
        'Current medicine list',
        'Recent health readings',
        'Symptoms and when they began',
        'Questions for the healthcare provider',
        'Medical documents',
        'Emergency contact information',
      ],
    ),
    CareBookChapter(
      number: 9,
      title: 'Organizing Important Information',
      readingTime: '3 min read',
      iconName: 'organize',
      paragraphs: [
        'Keep essential information accurate and easy for trusted family members to find when it is needed.',
      ],
      checklist: [
        'Emergency contacts and healthcare providers',
        'Medication list and allergies',
        'Medical conditions and appointments',
        'Insurance information',
        'Preferred hospital',
      ],
    ),
    CareBookChapter(
      number: 10,
      title: 'Taking Care of Yourself as a Caregiver',
      readingTime: '3 min read',
      iconName: 'selfCare',
      paragraphs: [
        'Caregivers also need sleep, regular meals, rest, social support, personal time, and their own medical care.',
        'Notice signs of exhaustion and make a realistic plan for breaks before responsibilities feel unmanageable.',
      ],
      highlight:
          'Taking care of yourself helps you provide safer and more sustainable care.',
    ),
    CareBookChapter(
      number: 11,
      title: 'Asking Family and Professionals for Help',
      readingTime: '3 min read',
      iconName: 'help',
      paragraphs: [
        'Care responsibilities can be shared among relatives, friends, community organizations, and qualified health professionals.',
        'Ask for specific help so other people understand what would make the biggest difference.',
      ],
      checklist: [
        'Tasks I can manage',
        'Tasks another family member can help with',
        'Tasks requiring professional assistance',
      ],
    ),
    CareBookChapter(
      number: 12,
      title: 'Emergency Preparation',
      readingTime: '4 min read',
      iconName: 'emergency',
      paragraphs: [
        'A simple emergency plan helps family members respond more calmly and locate important information quickly.',
      ],
      checklist: [
        'Emergency contact numbers',
        'Medical information and medicine list',
        'Transportation plan',
        'Hospital preference',
        'Emergency bag',
        'Clear instructions for family members',
      ],
    ),
  ];
}
