# frozen_string_literal: true


# key value pairs of all maine towns/cities and counties

# Source Code for getting these values:
# Add mechanize to gem file
# This source code didn't include the cities listed in the first table here (I.E. Bangor, etc.) those were added manually
# agent = Mechanize.new
# agent.log = Logger.new "mech.log"
# agent.user_agent_alias = 'Mac Safari'
# agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
# page = agent.get('https://en.wikipedia.org/wiki/List_of_municipalities_in_Maine')
# doc = Nokogiri::HTML(page.body)
# cities_and_counties_tables =  doc.css('table').select { |table| table[:class] == "sortable wikitable" }.map(&:to_s).flatten.pop
# sanitized_array = ActionView::Base.full_sanitizer.sanitize(cities_and_counties_tables).split("\n").reject { |value| value == "" || !value[/\d/].nil? || ["Town", "County", "Land area(sq mil)"].include?(value) }
# county_and_city_names = sanitized_array
# counties = county_and_city_names.find_all { |county_or_city_name| county_and_city_names.count(county_or_city_name) > 1 }.uniq
# hash_of_counties_and_cities = Hash[counties.map { |county_name| [county_name, []] }]
# county_and_city_names.each do |county_or_city_name|
  # Is a county
  # next if county_and_city_names.count(county_or_city_name) > 1
  # position of city/town in array
  # position_of_town = county_and_city_names.index(county_or_city_name)
  # county_name = county_and_city_names[position_of_town + 1]
  # puts("County name for #{county_or_city_name} is #{county_name}")
  # hash_of_counties_and_cities[county_name] << county_or_city_name
# end
# hash_of_counties_and_cities
# https://en.wikipedia.org/wiki/List_of_municipalities_in_Maine
# rubocop:disable Metrics/ModuleLength
module MeCountyHelper
  # rubocop:disable Metrics/MethodLength
  def maine_counties_and_towns
    {
      "Cumberland" =>
        [
          "Westbrook",
          "South Portland",
          "Brunswick",
          "Scarborough",
          "Windham",
          "Gorham",
          "Falmouth",
          "Standish",
          "Cape Elizabeth",
          "Yarmouth",
          "Freeport",
          "Gray",
          "New Gloucester",
          "Bridgton",
          "Harpswell",
          "Raymond",
          "Naples",
          "Casco",
          "North Yarmouth",
          "Harrison",
          "Sebago",
          "Baldwin",
          "Pownal",
          "Chebeague Island",
          "Long Island",
          "Frye Island",
          "Portland"
       ],
      "York" =>
        [
          "York",
          "Biddeford",
          "Sanford",
          "Saco",
          "Kennebunk",
          "Wells",
          "Kittery",
          "Old Orchard Beach",
          "Buxton",
          "Waterboro",
          "Berwick",
          "South Berwick",
          "Eliot",
          "Lebanon",
          "North Berwick",
          "Hollis",
          "Lyman",
          "Arundel",
          "Limington",
          "Kennebunkport",
          "Alfred",
          "Limerick",
          "Shapleigh",
          "Acton",
          "Dayton",
          "Parsonsfield",
          "Newfield",
          "Cornish",
          "Ogunquit"
],
      "Penobscot" =>
    ["Old Town",
     "Brewer",
     "Bangor",
     "Orono",
     "Hampden",
     "Hermon",
     "Glenburn",
     "Millinocket",
     "Dexter",
     "Orrington",
     "Newport",
     "Holden",
     "Milford",
     "Levant",
     "Corinth",
     "Carmel",
     "Eddington",
     "Corinna",
     "Veazie",
     "East Millinocket",
     "Enfield",
     "Hudson",
     "Newburgh",
     "Greenbush",
     "Bradley",
     "Charleston",
     "Plymouth",
     "Kenduskeag",
     "Medway",
     "Bradford",
     "Etna",
     "Howland",
     "Stetson",
     "Dixmont",
     "Garland",
     "Exeter",
     "Patten",
     "Clifton",
     "Lee",
     "Alton",
     "Lagrange",
     "Mattawamkeag",
     "Chester",
     "Springfield",
     "Burlington",
     "Winn",
     "Stacyville",
     "Lowell",
     "Passadumkeag",
     "Woodville",
     "Mount Chase",
     "Edinburg",
     "Lakeville",
     "Maxfield"],
      "Androscoggin" =>
 [
  "Auburn",
  "Lisbon",
  "Turner",
  "Poland",
  "Sabattus",
  "Greene",
  "Durham",
  "Livermore Falls",
  "Mechanic Falls",
  "Minot",
  "Leeds",
  "Livermore",
  "Wales",
  "Lewiston"
 ],
      "Sagadahoc" =>
  ["Bath",
   "Topsham",
   "Richmond",
   "Bowdoin",
   "Woolwich",
   "Bowdoinham",
   "Phippsburg",
   "West Bath",
   "Georgetown",
   "Arrowsic"],
      "Somerset" =>
  ["Skowhegan",
   "Fairfield",
   "Madison",
   "Pittsfield",
   "Norridgewock",
   "Anson",
   "Canaan",
   "St. Albans",
   "Palmyra",
   "Hartland",
   "Cornville",
   "Solon",
   "Athens",
   "Smithfield",
   "Embden",
   "Harmony",
   "Bingham",
   "Jackman",
   "Detroit",
   "New Portland",
   "Mercer",
   "Starks",
   "Moscow",
   "Ripley",
   "Cambridge",
   "Moose River",
   "Caratunk"],
      "Kennebec" =>
  ["Hallowell",
   "Gardiner",
   "Augusta",
   "Waterville",
   "Winslow",
   "Oakland",
   "Winthrop",
   "Vassalboro",
   "China",
   "Sidney",
   "Monmouth",
   "Litchfield",
   "West Gardiner",
   "Clinton",
   "Belgrade",
   "Farmingdale",
   "Chelsea",
   "Benton",
   "Pittston",
   "Windsor",
   "Manchester",
   "Readfield",
   "Albion",
   "Randolph",
   "Mount Vernon",
   "Wayne",
   "Fayette",
   "Rome",
   "Vienna"],
      "Franklin" =>
  ["Farmington",
   "Jay",
   "Wilton",
   "New Sharon",
   "Chesterville",
   "Strong",
   "Rangeley",
   "Phillips",
   "Kingfield",
   "Industry",
   "New Vineyard",
   "Carrabassett Valley",
   "Eustis",
   "Carthage",
   "Temple",
   "Avon",
   "Weld"],
      "Aroostook" =>
  ["Caribou",
   "Presque Isle",
   "Houlton",
   "Fort Kent",
   "Madawaska",
   "Fort Fairfield",
   "Limestone",
   "Van Buren",
   "Mapleton",
   "Washburn",
   "Mars Hill",
   "Hodgdon",
   "Ashland",
   "Easton",
   "Woodland",
   "Frenchville",
   "Littleton",
   "Linneus",
   "Eagle Lake",
   "Island Falls",
   "Sherman",
   "Monticello",
   "St. Agatha",
   "Oakfield",
   "Blaine",
   "New Sweden",
   "Bridgewater",
   "Wallagrass",
   "Westfield",
   "New Limerick",
   "St. Francis",
   "Chapman",
   "Grand Isle",
   "Smyrna",
   "Castle Hill",
   "Ludlow",
   "Portage Lake",
   "Perham",
   "New Canada",
   "Caswell",
   "Wade",
   "Merrill",
   "Crystal",
   "Stockholm",
   "Masardis",
   "Amity",
   "Allagash",
   "Weston",
   "Hamlin",
   "Dyer Brook",
   "Orient",
   "Haynesville",
   "Hammond",
   "Hersey",
   "Westmanland"],
      "Oxford" =>
  ["Rumford",
   "Paris",
   "Norway",
   "Fryeburg",
   "Bethel",
   "Mexico",
   "Dixfield",
   "Buckfield",
   "West Paris",
   "Otisfield",
   "Brownfield",
   "Hiram",
   "Waterford",
   "Peru",
   "Porter",
   "Hebron",
   "Woodstock",
   "Hartford",
   "Denmark",
   "Lovell",
   "Canton",
   "Sumner",
   "Greenwood",
   "Andover",
   "Stow",
   "Sweden",
   "Roxbury",
   "Newry",
   "Hanover",
   "Stoneham",
   "Gilead",
   "Byron",
   "Upton"],
      "Hancock" =>
  ["Ellsworth",
   "Bar Harbor",
   "Bucksport",
   "Blue Hill",
   "Orland",
   "Mount Desert",
   "Deer Isle",
   "Southwest Harbor",
   "Gouldsboro",
   "Dedham",
   "Lamoine",
   "Tremont",
   "Trenton",
   "Surry",
   "Castine",
   "Sullivan",
   "Sedgwick",
   "Stonington",
   "Brooksville",
   "Brooklin",
   "Otis",
   "Verona Island",
   "Mariaville",
   "Winter Harbor",
   "Eastbrook",
   "Waltham",
   "Swan's Island",
   "Sorrento",
   "Amherst",
   "Cranberry Isles",
   "Aurora",
   "Osborn",
   "Frenchboro",
   "Great Pond"],
      "Lincoln" =>
  ["Waldoboro",
   "Wiscasset",
   "Boothbay",
   "Bristol",
   "Jefferson",
   "Whitefield",
   "Damariscotta",
   "Boothbay Harbor",
   "Newcastle",
   "Dresden",
   "Nobleboro",
   "Edgecomb",
   "South Bristol",
   "Bremen",
   "Westport Island",
   "Alna",
   "Southport",
   "Somerville"],
      "Knox" =>
  ["Rockland",
   "Camden",
   "Warren",
   "Rockport",
   "Thomaston",
   "St. George",
   "Union",
   "Hope",
   "South Thomaston",
   "Owls Head",
   "Cushing",
   "Appleton",
   "Vinalhaven",
   "Friendship",
   "North Haven",
   "Isle au Haut"],
      "Piscataquis" =>
  ["Dover-Foxcroft",
   "Milo",
   "Greenville",
   "Guilford",
   "Sangerville",
   "Brownville",
   "Parkman",
   "Abbot",
   "Monson",
   "Sebec",
   "Medford",
   "Wellington",
   "Shirley",
   "Willimantic",
   "Beaver Cove",
   "Bowerbank"],
      "Waldo" =>
  ["Belfast",
   "Winterport",
   "Searsport",
   "Lincolnville",
   "Unity",
   "Stockton Springs",
   "Northport",
   "Palermo",
   "Searsmont",
   "Swanville",
   "Burnham",
   "Frankfort",
   "Brooks",
   "Montville",
   "Troy",
   "Liberty",
   "Belmont",
   "Monroe",
   "Thorndike",
   "Morrill",
   "Freedom",
   "Prospect",
   "Islesboro",
   "Jackson"],
      "Washington" =>
  ["Easport",
   "Calais",
   "Machias",
   "Baileyville",
   "Jonesport",
   "East Machias",
   "Lubec",
   "Milbridge",
   "Addison",
   "Cherryfield",
   "Steuben",
   "Machiasport",
   "Harrington",
   "Perry",
   "Pembroke",
   "Princeton",
   "Danforth",
   "Jonesboro",
   "Robbinston",
   "Columbia Falls",
   "Marshfield",
   "Beals",
   "Cutler",
   "Alexander",
   "Whiting",
   "Columbia",
   "Dennysville",
   "Charlotte",
   "Roque Bluffs",
   "Topsfield",
   "Whitneyville",
   "Meddybemps",
   "Cooper",
   "Northfield",
   "Vanceboro",
   "Crawford",
   "Waite",
   "Wesley",
   "Talmadge",
   "Deblois",
   "Beddington",
   "Lambert Lake"]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
