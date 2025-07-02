import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  // Map Configuration Parameters
  static const Map<String, dynamic> mapConfig = {
    'center': LatLng(31.4415, 31.495), // Adjusted to be in the middle
    'zoom': 17.0,
    'minZoom': 16.0,
    'maxZoom': 19.0,
    'maxBounds': [
      LatLng(31.434, 31.487), // Southwest (with padding)
      LatLng(31.449, 31.503), // Northeast (with padding)
    ],
    'maxBoundsViscosity': 1.0,
  };

  // Color Configuration
  static const Map<String, Color> colors = {
    'EDUCATIONAL_BUILDINGS': Color(0xFF2C3E50),
    'RESIDENTIAL_BUILDINGS': Color(0xFF34495E),
    'OTHER_BUILDINGS': Color(0xFF7F8C8D),
    'SPORTS_FACILITIES': Color(0xFF27AE60),
    'RESEARCH_FACILITIES': Color(0xFFE67E22),
    'RELIGIOUS_BUILDINGS': Color(0xFF8E44AD),
    'GREEN_SPACES': Color(0xFF2ECC71),
    'MAIN_ROADS': Color(0xFF95A5A6),
    'SECONDARY_ROADS': Color(0xFFBDC3C7),
    'PARKING_AREAS': Color(0xFF3498DB),
    'UNIVERSITY_BORDER': Color(0xFFE74C3C),
    'DEFAULT': Colors.transparent,
    'SUCCESS': Color(0xFF27AE60), // Added for success notifications
    'ERROR': Color(0xFFE74C3C), // Added for error notifications
    'WARNING': Color(0xFFFFB300), // Added for warning notifications
  };

  // Place Categories
  static const Map<String, List<String>> placeCategories = {
    'EDUCATIONAL_BUILDINGS': [
      'Phar_building',
      'Vet_AI_building',
      'Eng_building',
      'business_building',
      'med_building',
      'dental_building',
      'PT_building',
    ],
    'RESIDENTIAL_BUILDINGS': ['University housing'],
    'SPORTS_FACILITIES': [
      'paddle_field',
      'football_field',
      'tennis_field',
      'basketball_field',
      'pool_area',
      'Pool',
    ],
    'RESEARCH_FACILITIES': ['phar_research', 'Copy_Centre', 'ISO'],
    'RELIGIOUS_BUILDINGS': ['Mosque'],
    'OTHER_BUILDINGS': [
      'Housing and Development Bank',
      'ROLLS',
      'Fresh',
      'Hamza',
      'cafeteria',
      'cafeteria2',
    ],
    'GREEN_SPACES': [
      'phar_garden1',
      'phar_garden2',
      'phar_garden3',
      'phar_garden4',
      'phar_garden5',
      'garden1',
      'garden2',
      'garden3',
      'garden4',
      'med_garden1',
      'med_garden2',
      'med_garden3',
      'med_garden5',
      'med_garden6',
      'cf_garden1',
      'cf_garden2',
      'cf_garden3',
      'cf_garden4',
      'PT_south_garden',
      'green',
      'green_entrance',
    ],
    'MAIN_ROADS': [
      'sports_street',
      'main_street',
      'Ai_street',
      'entrance_street',
    ],
    'SECONDARY_ROADS': [
      'ai_pathway',
      'AI_pathway',
      'eng_pathway',
      'business_pathway',
      'med_pathway',
      'med_pathway2',
      'cafeteria_pathway',
      'cafeteria_pathway1',
      'cafeteria_pathway2',
      'cafeteria_pathway3',
      'phar_pathway',
      'PT_sidewalk',
      'B_Phar_avenue',
      'B_Phar_avenue2',
      'street_to_University_housing',
      'street_to_mosque',
      'PT_med_street',
      'Ai_backstreet',
    ],
    'PARKING_AREAS': [
      'bus_parking_area',
      'bus_parking_inside',
      'dental_parking',
    ],
  };

  // Faculty Buildings
  static const List<String> facultyBuildings = [
    'Phar_building',
    'Vet_AI_building',
    'Eng_building',
    'business_building',
    'med_building',
    'dental_building',
    'PT_building',
    'faculty of medicine',
    'faculty of engineering',
    'faculty of physical therapy',
    'faculty of pharmacy',
    'faculty of commerce',
    'faculty of artificial intelligence',
    'faculty of energy engineering',
    'law_energy_building',
  ];

  // College Images
  static const Map<String, Map<String, String>> collegeImages = {
    'Phar_building': {
      'name': 'Faculty of Pharmacy',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Pharmacy.jpg',
    },
    'Vet_AI_building': {
      'name': 'Veterinary and AI Building',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Artificial Intelligence.jpg',
    },
    'Eng_building': {
      'name': 'Faculty of Engineering',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Engineering.jpg',
    },
    'business_building': {
      'name': 'Faculty of Business',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Business.jpg',
    },
    'med_building': {
      'name': 'Medical Facility',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Medicine.jpg',
    },
    'dental_building': {
      'name': 'Dental Facility',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Oral & Dental Medicine.jpg',
    },
    'PT_building': {
      'name': 'Physical Therapy Building',
      'imageUrl': 'assets/Map/MapIMG/Faculty of Physical Therapy.jpg',
    },
    'law_energy_building': {
      'name': 'Law and Energy Building',
      'imageUrl': 'assets/Map/MapIMG/law_energy_building.jpg',
    },
  };

  // Links for Features
  static const Map<String, String> links = {
    'Eng_building': 'https://engineering.deltauniv.edu.eg/en/home/index',
    'med_building': 'https://medicine.deltauniv.edu.eg/en/home/index',
    'Phar_building': 'https://dentistry.deltauniv.edu.eg/en/home/index',
    'Vet_AI_building': 'https://ai.deltauniv.edu.eg/en/home/index',
    'business_building': 'https://business.deltauniv.edu.eg/en/home/index',
    'dental_building': 'https://dentistry.deltauniv.edu.eg/en/home/index',
    'PT_building': 'https://physicaltherapy.deltauniv.edu.eg/en/home/index',
    'law_energy_building': 'https://www.deltauniv.edu.eg/law/',
    'default': '#',
  };

  // Check if a building is a faculty
  static bool isFacultyBuilding(String name) {
    return facultyBuildings.contains(name) ||
        name.toLowerCase().contains('faculty');
  }

  // Get feature color based on location name
  static Color getFeatureColor(String name) {
    for (final entry in placeCategories.entries) {
      if (entry.value.contains(name)) {
        return colors[entry.key]!;
      }
    }
    return colors['DEFAULT']!;
  }

  // Get feature description based on name
  static String getFeatureDescription(String name) {
    const descriptions = {
      'Eng_building':
          'Delta University for Science and Technology in Mansoura, established by Presidential Decree No. 147 in 2007, is the first private university in the Egyptian Delta and Lower Egypt. The Faculty of Engineering, covering 2% of the 50-acre campus, began studies in 2008/2009 and includes various departments, lecture halls, and labs.',
      'med_building':
          'The Faculty of Medicine at Delta University was established by Presidential Decree No. 546 on October 21, 2019, as the university is sixth faculty. It aims to excel in medical education and research at national and regional levels.',
      'Phar_building':
          'The Faculty of Pharmacy at Delta University, established in 2011, aims for excellence through continuous curriculum development, quality assurance, and adherence to national standards. It fosters scientific competition and prepares graduates professionally for the job market to serve their community.',
      'Vet_AI_building':
          'In 2021, Delta University established the Faculty of Artificial Intelligence as a gift to students from Egypt, the Arab world, and Africa. This faculty serves as a key pillar for Egypt\'s Vision 2030, fostering innovation and excellence in AI to prepare students for the future.',
      'business_building':
          'The Faculty of Business Administration at Delta University was established by Presidential Decree No. 147 in 2007. It strives for excellence through continuous curriculum development, quality assurance, and academic standards, fostering a competitive and innovative learning environment.',
      'dental_building':
          'The Faculty of Oral and Dental Medicine at Delta University, established in 2011, is one of the largest private dental schools in Egypt, covering 7,200 m² within the main campus. Located on the International Coastal Road in Dakahlia, it is easily accessible from various governorates. The university provides shuttle services to cities like Cairo, Alexandria, and Port Said, with additional access via public or private transportation.',
      'PT_building':
          'The Faculty of Physical Therapy at Delta University was approved by Presidential Decree No. 90 on 17/4/2010, with studies commencing under Ministerial Resolution No. 2485 on 20/7/2014. Physical therapy, an ancient practice, has evolved into an essential therapeutic system that promotes health, enhances performance, and treats various disorders.',
      'law_energy_building':
          'Delta University Faculty of Energy Engineering – the university’s newest faculty. Includes Petroleum Engineering, Gas and Petrochemicals, and Renewable Energy departments. Prepares students for careers in modern energy sectors.',
      'default': 'No description available for this location.',
    };
    return descriptions[name] ?? descriptions['default']!;
  }
}
