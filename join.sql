.headers on
.mode csv

SELECT Parcel.id,
  Parcel.longitude,
  Parcel.latitude,
  Parcel.address_number,
  Street.name AS 'street',
  City.name AS 'city',
  Property_Type.name AS 'property_type',
  Unit.name AS 'unit'
FROM Parcel
  JOIN Street ON Parcel.street_id = Street.id
  JOIN City ON Parcel.city_id = City.id
  JOIN Property_Type ON Parcel.property_type_id = Property_Type.id
  LEFT JOIN Unit ON Parcel.unit_id = Unit.id
ORDER BY
  Parcel.id;
