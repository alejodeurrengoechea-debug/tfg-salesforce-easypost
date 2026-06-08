/**
 * @description Clase utilitaria.
 * @author Alejo De Urrengoechea
 */
public class SObjectAccessUtil {

    /**
     * @description Verifica que el usuario tiene acceso de lectura al objeto indicado.
     * @param objectType Tipo de objeto a verificar.
     * @return true si el objeto es accesible, false en caso contrario.
     */
    public static Boolean isAccessible(Schema.SObjectType objectType) {
        return objectType.getDescribe().isAccessible();
    }
}