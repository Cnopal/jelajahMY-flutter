USE `jelajahmy`;

START TRANSACTION;

INSERT IGNORE INTO states (
    id,
    name,
    code,
    description,
    image_url
) VALUES
(1, 'Kuala Lumpur', 'KUL',
 'The capital city of Malaysia known for modern landmarks, shopping and cultural attractions.',
 NULL),

(2, 'Melaka', 'MLK',
 'A historical state known for heritage buildings, museums and multicultural influences.',
 NULL),

(3, 'Penang', 'PNG',
 'A destination known for heritage areas, food, beaches and cultural attractions.',
 NULL),

(4, 'Pahang', 'PHG',
 'A state featuring highlands, rainforests, beaches and nature-based destinations.',
 NULL),

(5, 'Sabah', 'SBH',
 'A Malaysian state on Borneo known for mountains, islands and natural attractions.',
 NULL),

(6, 'Sarawak', 'SWK',
 'A Malaysian state on Borneo known for cultural diversity, rainforests and heritage destinations.',
 NULL);


INSERT IGNORE INTO categories (
    id,
    name,
    description
) VALUES
(1, 'Historical',
 'Historical buildings, monuments, museums and heritage locations.'),

(2, 'Nature',
 'Natural attractions including mountains, parks, beaches and rainforests.'),

(3, 'Cultural',
 'Cultural attractions, traditional locations and community heritage.'),

(4, 'Adventure',
 'Outdoor, recreational and adventure-based attractions.'),

(5, 'Shopping',
 'Shopping districts, markets and retail destinations.'),

(6, 'Family',
 'Family-friendly attractions and recreational destinations.');


INSERT IGNORE INTO attractions (
    id,
    state_id,
    category_id,
    name,
    description,
    address,
    latitude,
    longitude,
    opening_hours,
    entrance_fee,
    image_url
) VALUES
(
    1,
    1,
    6,
    'Petronas Twin Towers',
    'An iconic landmark located in the centre of Kuala Lumpur.',
    'Kuala Lumpur City Centre, Kuala Lumpur',
    3.1579000,
    101.7117000,
    'Refer to official source',
    0.00,
    NULL
),
(
    2,
    1,
    6,
    'Kuala Lumpur Tower',
    'A telecommunications tower offering panoramic views of Kuala Lumpur.',
    'Jalan Puncak, Kuala Lumpur',
    3.1528000,
    101.7038000,
    'Refer to official source',
    0.00,
    NULL
),
(
    3,
    2,
    1,
    'A Famosa',
    'A historical Portuguese fortress landmark located in Melaka.',
    'Bandar Hilir, Melaka',
    2.1919000,
    102.2505000,
    'Open public area',
    0.00,
    NULL
),
(
    4,
    2,
    5,
    'Jonker Street',
    'A heritage street known for shops, local products and food.',
    'Jalan Hang Jebat, Melaka',
    2.1941000,
    102.2482000,
    'Varies by business',
    0.00,
    NULL
),
(
    5,
    3,
    1,
    'George Town Heritage Area',
    'A heritage district featuring historical architecture and cultural attractions.',
    'George Town, Penang',
    5.4141000,
    100.3288000,
    'Open public area',
    0.00,
    NULL
),
(
    6,
    3,
    2,
    'Penang Hill',
    'A highland destination offering natural scenery and panoramic views.',
    'Bukit Bendera, Penang',
    5.4244000,
    100.2683000,
    'Refer to official source',
    0.00,
    NULL
),
(
    7,
    4,
    2,
    'Cameron Highlands',
    'A highland destination known for cool weather, farms and natural scenery.',
    'Cameron Highlands, Pahang',
    4.4710000,
    101.3760000,
    'Varies by attraction',
    0.00,
    NULL
),
(
    8,
    4,
    4,
    'Taman Negara',
    'A rainforest destination offering nature and outdoor activities.',
    'Kuala Tahan, Pahang',
    4.3820000,
    102.4010000,
    'Refer to official source',
    0.00,
    NULL
),
(
    9,
    5,
    2,
    'Mount Kinabalu',
    'A major natural landmark and mountain destination in Sabah.',
    'Kinabalu Park, Sabah',
    6.0750000,
    116.5580000,
    'Permit and schedule required',
    0.00,
    NULL
),
(
    10,
    5,
    3,
    'Kota Kinabalu City Mosque',
    'A notable mosque and cultural landmark in Kota Kinabalu.',
    'Kota Kinabalu, Sabah',
    5.9950000,
    116.1070000,
    'Refer to official source',
    0.00,
    NULL
),
(
    11,
    6,
    3,
    'Kuching Waterfront',
    'A riverside destination featuring public spaces, food and cultural landmarks.',
    'Kuching, Sarawak',
    1.5573000,
    110.3441000,
    'Open public area',
    0.00,
    NULL
),
(
    12,
    6,
    2,
    'Bako National Park',
    'A national park featuring rainforest trails, wildlife and coastal scenery.',
    'Kuching Division, Sarawak',
    1.7167000,
    110.4667000,
    'Refer to official source',
    0.00,
    NULL
);

COMMIT;