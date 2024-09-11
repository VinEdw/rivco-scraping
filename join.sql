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
FROM
  Parcel JOIN Street JOIN City JOIN Property_Type JOIN Unit
ON
  Parcel.street_id = Street.id
  AND Parcel.city_id = City.id
  AND Parcel.property_type_id = Property_Type.id
  AND Parcel.unit_id = Unit.id
WHERE
  Parcel.street_id IS NOT NULL
ORDER BY
  Parcel.id
