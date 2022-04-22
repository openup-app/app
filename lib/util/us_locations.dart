// Map of US states to a list of their 7 biggest most-populus in alphabetical order.
// Taken from https://www.cdc.gov/places/about/500-cities-2016-2019/pdfs/500-cities-by-state.pdf
const usLocations = {
  'Alabama': [
    'Birmingham',
    'Hoover',
    'Huntsville',
    'Mobile',
    'Montgomery',
    'Tuscaloosa',
  ],
  'Alaska': [
    'Anchorage',
  ],
  'Arizona': [
    'Chandler',
    'Gilbert',
    'Glendale',
    'Mesa',
    'Phoenix',
    'Scottsdale',
    'Tucson'
  ],
  'Arkansas': [
    'Fayetteville',
    'Fort Smith',
    'Jonesboro',
    'Little Rock',
    'Springdale',
  ],
  'California': [
    'Fresno',
    'Long Beach',
    'Los Angeles',
    'Sacramento',
    'San Diego',
    'San Francisco',
    'San Jose'
  ],
  'Colorado Denver': [
    'Colorado Springs',
    'Aurora',
    'Fort Collins',
    'Lakewood',
    'Thornton',
    'Pueblo',
  ],
  'Connecticut': [
    'Aurora',
    'Colorado Springs',
    'Fort Collins',
    'Lakewood',
    'Pueblo',
    'Thornton'
  ],
  'Delaware': [
    'Wilmington',
  ],
  'District of Columbia': [
    'Washington',
  ],
  'Florida': [
    'Hialeah',
    'Jacksonville',
    'Miami',
    'Orlando',
    'St. Petersburg',
    'Tallahassee',
    'Tampa'
  ],
  'Georgia': [
    'Athens-Clarke County',
    'Atlanta',
    'Augusta-Richmond County',
    'Columbus',
    'Macon',
    'Sandy Springs',
    'Savannah'
  ],
  'Hawaii': [
    'Honolulu',
  ],
  'Idaho': [
    'Boise City',
    'Meridian',
    'Nampa',
  ],
  'Illinois': [
    'Aurora',
    'Chicago',
    'Joliet',
    'Naperville',
    'Peoria',
    'Rockford',
    'Springfield'
  ],
  'Indiana': [
    'Bloomington',
    'Evansville',
    'Fort Wayne',
    'Gary',
    'Hammond',
    'Indianapolis',
    'South Bend'
  ],
  'Iowa': [
    'Cedar Rapids',
    'Davenport',
    'Des Moines',
    'Iowa City',
    'Sioux City',
    'Waterloo'
  ],
  'Kansas': [
    'Kansas City',
    'Lawrence',
    'Olathe',
    'Overland Park',
    'Topeka',
    'Wichita'
  ],
  'Kentucky': [
    'Lexington-Fayette County',
    'Louisville/Jefferson County',
  ],
  'Louisiana': [
    'Baton Rouge',
    'Kenner',
    'Lafayette',
    'Lake Charles',
    'New Orleans',
    'Shreveport',
  ],
  'Maine': [
    'Portland',
  ],
  'Mayland': [
    'Baltimore',
  ],
  'Massachusetts': [
    'Boston',
    'Brockton',
    'Cambridge',
    'Lowell',
    'New Bedford',
    'Springfield',
    'Worcester',
  ],
  'Michigan': [
    'Ann Arbor',
    'Detroit',
    'Flint',
    'Grand Rapids',
    'Lansing',
    'Sterling Heights',
    'Warren'
  ],
  'Minnesota': [
    'Bloomington',
    'Brooklyn Park',
    'Duluth',
    'Minneapolis',
    'Plymouth',
    'Rochester',
    'St. Paul'
  ],
  'Mississippi': [
    'Gulfport',
    'Jackson',
  ],
  'Missouri': [
    'Columbia',
    'Independence',
    'Kansas City',
    'Lee\'s Summit',
    'Springfield',
    'St. Louis'
  ],
  'Montana': [
    'Billings',
    'Missoula',
  ],
  'Nebraska': [
    'Lincoln',
    'Omaha',
  ],
  'Nevada': [
    'Henderson',
    'Las Vegas',
    'North Las Vegas',
    'Reno',
    'Sparks',
  ],
  'New Hampshire': [
    'Manchester',
    'Nashua',
  ],
  'New Jersey': [
    'Camden',
    'Clifton',
    'Elizabeth',
    'Jersey City',
    'Newark',
    'Paterson',
    'Trenton'
  ],
  'New Mexico': [
    'Albuquerque',
    'Las Cruces',
    'Rio Rancho',
    'Santa Fe',
  ],
  'New York': [
    'Albany',
    'Buffalo',
    'New Rochelle',
    'New York',
    'Rochester',
    'Syracuse',
    'Yonkers'
  ],
  'North Carolina': [
    'Cary',
    'Charlotte',
    'Durham',
    'Fayetteville',
    'Greensboro',
    'Raleigh',
    'Winston-Salem',
  ],
  'North Dakota': [
    'Fargo',
  ],
  'Ohio': [
    'Akron',
    'Cincinnati',
    'Cleveland',
    'Columbus',
    'Dayton',
    'Parma',
    'Toledo',
  ],
  'Oklahoma': [
    'Broken Arrow',
    'Edmond',
    'Lawton',
    'Norman',
    'Oklahoma City',
    'Tulsa',
  ],
  'Oregon': [
    'Beaverton',
    'Bend',
    'Eugene',
    'Gresham',
    'Hillsboro',
    'Portland',
    'Salem',
  ],
  'Pennsylvania': [
    'Allentown',
    'Bethlehem',
    'Erie',
    'Philadelphia',
    'Pittsburgh',
    'Reading',
    'Scranton'
  ],
  'Rhode Island': [
    'Cranston',
    'Pawtucket',
    'Providence',
    'Warwick',
  ],
  'South Carolina': [
    'Charleston',
    'Columbia',
    'Mount Pleasant',
    'North Charleston',
    'Rock Hill',
  ],
  'South Dakota': [
    'Rapid City',
    'Sioux Falls',
  ],
  'Tennessee': [
    'Chattanooga',
    'Clarksville',
    'Knoxville',
    'Memphis',
    'Murfreesboro',
    'Nashville-Davidson',
  ],
  'Texas': [
    'Arlington',
    'Austin',
    'Dallas',
    'El Paso',
    'Fort Worth',
    'Houston',
    'San Antonio',
  ],
  'Utah': [
    'Ogden',
    'Orem',
    'Provo',
    'Salt Lake City',
    'Sandy',
    'West Jordan',
    'West Valley City',
  ],
  'Vermont': [
    'Burlington',
  ],
  'Virgina': [
    'Alexandria',
    'Chesapeake',
    'Hampton',
    'Newport News',
    'Norfolk',
    'Richmond',
    'Virginia Beach',
  ],
  'Washington': [
    'Bellevue',
    'Everett',
    'Kent',
    'Seattle',
    'Spokane',
    'Tacoma',
    'Vancouver',
  ],
  'West Virginia': [
    'Charleston',
  ],
  'Wisconsin': [
    'Appleton',
    'Green Bay',
    'Kenosha',
    'Madison',
    'Milwaukee',
    'Racine',
    'Waukesha',
  ],
  'Wyoming': [
    'Cheyenne',
  ]
};
