/**
 * @description Clases de transferencia de datos (DTOs) que representan
 *              el contrato JSON de la API de Shippo.
 * @author Alejo De Urrengoechea
 */
public class ShippoDTOs {

    /**
     * @description Payload principal del POST /shipments de Shippo.
     */
    public class ShippoPayload {
        public ShippoAddress address_from {get; set;}
        public ShippoAddress address_to   {get; set;}
        public List<ShippoParcel> parcels {get; set;}

        public ShippoPayload(ShippoAddress addressFrom, ShippoAddress addressTo, ShippoParcel parcel) {
            this.address_from = addressFrom;
            this.address_to   = addressTo;
            this.parcels      = new List<ShippoParcel>{ parcel };
        }
    }

    /**
     * @description Representa una dirección física en el contrato JSON de Shippo.
     */
    public class ShippoAddress {
        public String name    {get; set;}
        public String street1 {get; set;}
        public String city    {get; set;}
        public String state   {get; set;}
        public String zip     {get; set;}
        public String country {get; set;}
        public String email   {get; set;}
        public String phone   {get; set;}

        public ShippoAddress(
            String name,
            String street1,
            String city,
            String state,
            String zip,
            String country,
            String email,
            String phone
        ) {
            this.name    = name;
            this.street1 = street1;
            this.city    = city;
            this.state   = state;
            this.zip     = zip;
            this.country = country;
            this.email   = email;
            this.phone   = phone;
        }
    }

    /**
     * @description Representa las dimensiones y peso del paquete en el contrato JSON de Shippo.
     */
    public class ShippoParcel {
        public String length        {get; set;}
        public String width         {get; set;}
        public String height        {get; set;}
        public String distance_unit {get; set;}
        public String weight        {get; set;}
        public String mass_unit     {get; set;}

        public ShippoParcel(String length, String width, String height, String weight) {
            Shippo_Config__mdt config = Shippo_Config__mdt.getInstance('Default');
            this.length        = length;
            this.width         = width;
            this.height        = height;
            this.distance_unit = config.Distance_Unit__c;
            this.weight        = weight;
            this.mass_unit     = config.Mass_Unit__c;
        }
    }

    /**
     * @description Construye el JSON para el POST /transactions de Shippo.
     * @param rateId ID de la tarifa seleccionada devuelta por /shipments.
     * @return String JSON listo para usar como body del HTTP POST.
     */
    public static String buildTransactionJSON(String rateId) {
        Map<String, Object> body = new Map<String, Object>{
            'rate'            => rateId,
            'label_file_type' => 'PDF',
            'async'           => false
        };
        return JSON.serialize(body);
    }
}