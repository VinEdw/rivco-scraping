# Set the following variables from the command line:
# - 'territories_csv' Set to the name of the file with all the addresses

# Function returns the maximum of two input values
function max(x, y) {
  return x > y ? x : y;
}

# Function returns the minimum of two input values
function min(x, y) {
  return x < y ? x : y;
}

# Function to adjust the input string to use CSV escaping rules
function csv_escape_string(str) {
    # Escape " characters by doubling them to ""
    if (str ~ /"/) {
      gsub(/"/, "\"\"", str)
    }
    # If double quotes, commas, or newlines are present, surround the string in double quotes
    if (str ~ /[\n,"]/) {
      str = sprintf("\"%s\"", str)
    }
    return str
}

# Function to initialize an input array with territory boundaries
# This array maps territory numbers to lists of (lat, lng) points
# Pass in the name of the CSV file that contains the list of points in column 12
# The territory category code is found in column 2
# The territory number is found in column 4
# These lists have the structure [lng1,lat1],[lng2,lat2],[lng3,lat3],[lng4,lat4],...
function initialize_territory_boundaries(file, array) {
  row_num = 0
  while ((getline < (territories_csv)) > 0) {
    ++row_num;
    territory_number = $2 "-" $4;
    boundary_str = $12;
    # Skip the first row and territories without boundaries
    if (row_num == 1 || boundary_str == "") {
      continue;
    }
    # Parse the list of points
    gsub(/^\[|\]$/, "", boundary_str);
    pair_count = split(boundary_str, pairs, /\],\[/);
    for (i = 1; i <= pair_count; ++i) {
      pair = pairs[i];
      split(pair, coords, ",");
      lng = coords[1];
      lat = coords[2];
      # Add the coordinates as (lat, lng) to the array
      array[territory_number][i][1] = lat;
      array[territory_number][i][2] = lng;
    }
  }
  close(territories_csv)
}

# Function checks if a ray starting at a point (lat_0, lng_0) and extended along the longitude to greater latitudes
# intersects with a line segment connecting (lat_1, lng_1) and (lat_2, lng_2)
# Returns 1 if the ray does intersects
# Returns 0 if the ray does not intersect
#
# If the ray passes through at least one of the points, then only count the intersection if the other point has a greater longitude
# This prevents double counting the intersection in point_in_polygon()
# Effectively, this nudges the point to a slightly higher longitude for the purpose of the test
#
# Cases where the point is on the segment do not count
function check_for_intersection(lat_0, lng_0, lat_1, lng_1, lat_2, lng_2) {
  # Check if the line segment does not even cross the latitude of the ray
  # This happens when:
  # - Both ends of the line segment have a latitude that is too low
  # - Both ends of the line segment have a longitude that is too high
  # - Both ends of the line segment have a longitude that is too low
  if ((max(lat_1, lat_2) < lat_0) || (min(lng_1, lng_2) > lng_0) || (max(lng_1, lng_2) < lng_0)) {
    return 0;
  }
  # If the ray passes through at least one of the points, then only count the intersection if the other point has a greater longitude
  # This prevents double counting the intersection in point_in_polygon()
  if ((lng_1 == lng_0 && lat_1 > lat_0) || (lng_2 == lng_0 && lat_2 > lat_0)) {
    return max(lng_1, lng_2) > lng_0;
  }
  # After those checks, if both ends of the line segment have latitudes that are greater than lat_0, then the ray definitely intersects
  if (min(lat_1, lat_2) > lat_0) {
    return 1;
  }
  # Calculate the exact latitude where the line crosses the longitude level of the ray
  # If that latitude value is greater than the latitude of the point, then the line intersects the ray
  # Otherwise, the line does not intersect the ray
  slope = (lat_2 - lat_1) / (lng_2 - lng_1);
  lat_intersect = slope * (lng_0 - lng_1) + lat_1;
  return lat_intersect > lat_0;
}

# Function checks if a (lat, lng) point lies within a polygon defined by a list of points
# Returns 1 if the point is inside
# Returns 0 if the point is outside
# Points that lie on the edge of the polygon return an ambiguous result
function point_in_polygon(lat, lng, polygon_points) {
  intersection_count = 0;
  for (i = 1; i <= length(polygon_points); ++i) {
    # Set the initial point
    lat_1 = polygon_points[i][1];
    lng_1 = polygon_points[i][2];
    # Set the next point
    lat_2 = polygon_points[i % length(polygon_points) + 1][1];
    lng_2 = polygon_points[i % length(polygon_points) + 1][2];
    # Check for an intersection between the ray extended from the point and the polygon edge formed by the points
    intersection_count += check_for_intersection(lat, lng, lat_1, lng_1, lat_2, lng_2);
  }
  # If the intersection_count is even, then the point is outside the polygon
  # If the intersection_count is odd, then the point is inside the polygon
  return intersection_count % 2 != 0;
}

# Function to print an output row for the CSV with the assigned addresses
function print_output_row(territory_number, category_code, apartment_number, number, street, suburb, state, latitude, longitude, notes) {
  printf("%s,", csv_escape_string(territory_number));
  printf("%s,", csv_escape_string(category_code));
  printf("%s,", csv_escape_string(apartment_number));
  printf("%s,", csv_escape_string(number));
  printf("%s,", csv_escape_string(street));
  printf("%s,", csv_escape_string(suburb));
  printf("%s,", csv_escape_string(state));
  printf("%s,", csv_escape_string(latitude));
  printf("%s,", csv_escape_string(longitude));
  printf("%s\n", csv_escape_string(notes));
}

BEGIN {
  initialize_territory_boundaries(territories_csv, territory_boundaries);

  # Print the headers for the output CSV
  # 1. TerritoryNumber
  # 2. CategoryCode
  # 3. ApartmentNumber
  # 4. Number
  # 5. Street
  # 6. Suburb
  # 7. State
  # 8. Latitude
  # 9. Longitude
  # 10. Notes
  print("TerritoryNumber,CategoryCode,ApartmentNumber,Number,Street,Suburb,State,Latitude,Longitude,Notes");
}

# Check each address where the latitude and longitude are not null
NR != 1 && $2 != "" && $3 != "" {
  # Check if the address lies within each territory polygon
  # Assign the address to the first matching territory
  for (terr in territory_boundaries) {
    if (point_in_polygon($3, $2, territory_boundaries[terr])) {
      split(terr, split_terr, "-");
      print_output_row(split_terr[2], split_terr[1], $8, $4, $5, $6, "CA", $3, $2, $7);
      break;
    }
  }
}
