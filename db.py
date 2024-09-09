import sqlite3

def check_for_apn(cur: sqlite3.Cursor, apn: int) -> bool:
    """
    Check if an APN already exists in the database.
    """
    cur.execute("""SELECT 1 FROM Parcel WHERE id = (?)""", (apn,))
    result = cur.fetchone()
    return True if result != None else False

def get_street_id(cur: sqlite3.Cursor, street_name: None|str) -> None|int:
    """
    Get the id for the given street name, creating one if it does not exist.
    """
    if street_name == None:
        return None
    cur.execute("""INSERT OR IGNORE INTO Street (name) VALUES (?)""", (street_name,))
    cur.execute("""SELECT id FROM Street WHERE name = ?""", (street_name,))
    return cur.fetchone()[0]

def get_city_id(cur: sqlite3.Cursor, city_name: None|str) -> None|int:
    """
    Get the id for the given city name, creating one if it does not exist.
    """
    if city_name == None:
        return None
    cur.execute("""INSERT OR IGNORE INTO City (name) VALUES (?)""", (city_name,))
    cur.execute("""SELECT id FROM City WHERE name = ?""", (city_name,))
    return cur.fetchone()[0]

def get_property_type_id(cur: sqlite3.Cursor, property_type: None|str) -> None|int:
    """
    Get the id for the given property type, creating one if it does not exist.
    """
    if property_type == None:
        return None
    cur.execute("""INSERT OR IGNORE INTO Property_Type (name) VALUES (?)""", (property_type,))
    cur.execute("""SELECT id FROM Property_Type WHERE name = ?""", (property_type,))
    return cur.fetchone()[0]

def get_unit_id(cur: sqlite3.Cursor, unit: None|str) -> None|int:
    """
    Get the id for the given unit, creating one if it does not exist.
    """
    if unit == None:
        return None
    cur.execute("""INSERT OR IGNORE INTO Unit (name) VALUES (?)""", (unit,))
    cur.execute("""SELECT id FROM Unit WHERE name = ?""", (unit,))
    return cur.fetchone()[0]

def add_null_parcel(cur: sqlite3.Cursor, apn: int):
    """
    Add a parcel with all null data, except for the given APN.
    """
    cur.execute("""INSERT INTO Parcel (id) VALUES (?)""", (apn,))

def add_parcel(cur: sqlite3.Cursor, apn: int, parcel_data: dict):
    """
    Add a parcel with the given APN and parcel data.
    """
    cur.execute(
        """
        INSERT OR REPLACE INTO Parcel
        (id, longitude, latitude, address_number, street_id, city_id, property_type_id, unit_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            apn,
            parcel_data["longitude"],
            parcel_data["latitude"],
            parcel_data["address_number"],
            get_street_id(cur, parcel_data["street"]),
            get_city_id(cur, parcel_data["city"]),
            get_property_type_id(cur, parcel_data["property_type"]),
            get_unit_id(cur, parcel_data["unit"]),
        )
    )
