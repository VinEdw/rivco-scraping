from __future__ import annotations
import requests
import sqlite3
import db

con = sqlite3.connect("rivco.db")
cur = con.cursor()

def num_to_search_str(num: int):
    """
    Convert an integer to an 8 digit search string.
    """
    return f"{num:08}"

def apn_to_str(apn: int):
    """
    Convert an APN integer to a 9 digit string.
    """
    return f"{apn:09}"

def get_apn_possibilities(search_num: int) -> list[int]:
    """
    Get the possible APNs (9 digits) given a number with 8 digits.
    """
    search_str = num_to_search_str(search_num)
    possibilities = []
    for in_front in [False, True]:
        for i in range(10):
            possibilities.append(int(f"{i}{search_str}") if in_front else int(f"{search_str}{i}"))
    return possibilities

def request_apn_list(search_num: int) -> list[int]:
    """
    Get a list of valid APNs (9 digits) given a number with 8 digits.
    """
    url = "https://rivcoview.rivcoacr.org/data/ajaxcalls/db/getSearchResults.php"
    payload = {
        "field": "mv_Location:PIN",
        "term": num_to_search_str(search_num),
    }
    r = requests.get(url, params=payload)
    apn_list = [int(item["value"]) for item in r.json() if item != [] and item["value"].isdigit()]
    return apn_list

def request_parcel_data(apn: int):
    """
    Get the parcel data for the given APN.
    """
    url = "https://rivcoview.rivcoacr.org/data/ajaxcalls/db/getData.php"
    payload = {
        "field": "mv_Location:PIN",
        "qtype": "assessment_info",
        "value": apn_to_str(apn),
    }
    r = requests.post(url, data=payload)
    result = r.json()
    # Check if nothing was found, returning None in that case
    if len(result) == 0:
        return None
    # Store all the important parcel_data to return
    parcel_data = {}
    # Longitude and latitude
    parcel_data["longitude"] = float(result[0]["lng"]) if (result[0]["lng"] != None) else None
    parcel_data["latitude"] = float(result[0]["lat"]) if (result[0]["lat"] != None) else None
    # Property type
    parcel_data["property_type"] = result[0].get("class_code", None)
    # City
    parcel_data["city"] = result[0]["District"].split(maxsplit=1)[1] if (result[0]["District"] != None) else None
    # Address splitting
    address = result[0].get("address", None)
    if address == None:
        parcel_data["unit"] = None
        parcel_data["address_number"] = None
        parcel_data["street"] = None
    else:
        # Unit
        unit_pattern = " UNIT "
        apt_pattern = " APT "
        if unit_pattern in address:
            address, unit = address.split(unit_pattern)
        elif apt_pattern in address:
            address, unit = address.split(apt_pattern)
        else:
            unit = None
        parcel_data["unit"] = unit
        # Address number and street
        address_number, street = address.split(maxsplit=1)
        if not address_number.isdigit():
            address_number = None
            street = address
        parcel_data["address_number"] = address_number
        parcel_data["street"] = street
    return parcel_data

if __name__ == "__main__":
    # Iterate through the possible 8 digit numbers
    for i in range(100_000_000):
        apn_possibilites = get_apn_possibilities(i)
        if all(db.check_for_apn(cur, apn) for apn in apn_possibilites):
            continue
        apn_list = request_apn_list(i)
        for apn in apn_possibilites:
            print(apn_to_str(apn))
            if db.check_for_apn(cur, apn):
                print("\tAlready Checked")
            elif apn not in apn_list:
                print("\tInvalid APN")
                db.add_null_parcel(cur, apn)
            else:
                parcel_data = request_parcel_data(apn)
                if parcel_data == None:
                    print("\tNo Data Found")
                    db.add_null_parcel(cur, apn)
                else:
                    print("\tAdding Parcel")
                    db.add_parcel(cur, apn, parcel_data)
        # Save changes
        con.commit()
    # Close the connection
    con.close()
