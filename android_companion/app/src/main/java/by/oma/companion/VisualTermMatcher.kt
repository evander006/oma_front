package by.oma.companion

import java.util.Locale

/**
 * Conservative translation of ML Kit English visual labels to real OMA catalogue terms.
 * No invented SKUs or confidence percentages. Unknown/general labels return no terms.
 */
internal object VisualTermMatcher {
    private val mappings: List<Pair<String, List<String>>> = listOf(
        "power drill" to listOf("дрель", "шуруповерт"),
        "cordless drill" to listOf("дрель", "шуруповерт"),
        "power tool" to listOf("электроинструмент"),
        "screwdriver" to listOf("отвертка", "шуруповерт"),
        "drill" to listOf("дрель", "шуруповерт"),
        "angle grinder" to listOf("болгарка", "шлифмашина"),
        "grinder" to listOf("шлифмашина"),
        "hammer" to listOf("молоток"),
        "wrench" to listOf("ключ гаечный"),
        "pliers" to listOf("плоскогубцы"),
        "saw" to listOf("пила"),
        "ladder" to listOf("лестница", "стремянка"),
        "measuring tape" to listOf("рулетка"),
        "tape measure" to listOf("рулетка"),
        "tape" to listOf("лента"),
        "screw" to listOf("шуруп", "саморез"),
        "bolt" to listOf("болт"),
        "nail" to listOf("гвоздь"),
        "faucet" to listOf("смеситель"),
        "water tap" to listOf("смеситель"),
        "tap" to listOf("смеситель"),
        "sink" to listOf("мойка", "раковина"),
        "washbasin" to listOf("умывальник"),
        "bathtub" to listOf("ванна"),
        "shower" to listOf("душ", "лейка"),
        "toilet" to listOf("унитаз"),
        "pipe" to listOf("труба"),
        "valve" to listOf("кран", "вентиль"),
        "hose" to listOf("шланг"),
        "light fixture" to listOf("светильник"),
        "chandelier" to listOf("люстра"),
        "ceiling light" to listOf("светильник"),
        "light bulb" to listOf("лампа"),
        "bulb" to listOf("лампа"),
        "lamp" to listOf("светильник", "лампа"),
        "electric cable" to listOf("кабель"),
        "wire" to listOf("провод"),
        "socket" to listOf("розетка"),
        "switch" to listOf("выключатель"),
        "paint brush" to listOf("кисть"),
        "paint roller" to listOf("валик"),
        "paint bucket" to listOf("краска"),
        "paint" to listOf("краска"),
        "wallpaper" to listOf("обои"),
        "floor tile" to listOf("плитка"),
        "ceramic tile" to listOf("плитка"),
        "tile" to listOf("плитка"),
        "laminate" to listOf("ламинат"),
        "flooring" to listOf("покрытие напольное", "ламинат"),
        "door handle" to listOf("ручка дверная"),
        "door" to listOf("дверь"),
        "window" to listOf("окно"),
        "chair" to listOf("стул"),
        "armchair" to listOf("кресло"),
        "sofa" to listOf("диван"),
        "couch" to listOf("диван"),
        "table" to listOf("стол"),
        "cabinet" to listOf("шкаф", "тумба"),
        "shelf" to listOf("полка"),
        "desk" to listOf("стол"),
        "bed" to listOf("кровать"),
        "mattress" to listOf("матрас"),
        "mirror" to listOf("зеркало"),
        "carpet" to listOf("ковер"),
        "curtain" to listOf("штора"),
        "kitchen appliance" to listOf("техника для кухни"),
        "refrigerator" to listOf("холодильник"),
        "microwave" to listOf("микроволновая печь"),
        "kettle" to listOf("чайник"),
        "vacuum cleaner" to listOf("пылесос"),
        "washing machine" to listOf("стиральная машина"),
        "iron" to listOf("утюг"),
        "bucket" to listOf("ведро"),
        "broom" to listOf("веник", "щетка"),
        "brush" to listOf("щетка", "кисть"),
        "glove" to listOf("перчатки"),
        "plant pot" to listOf("горшок"),
        "flower pot" to listOf("горшок"),
        "flower" to listOf("растение"),
        "plant" to listOf("растение"),
        "garden hose" to listOf("шланг"),
        "lawn mower" to listOf("газонокосилка"),
        "lawn" to listOf("газон"),
        "grill" to listOf("гриль", "мангал"),
        "wheelbarrow" to listOf("тачка"),
        "shovel" to listOf("лопата"),
        "rake" to listOf("грабли"),
        "basket" to listOf("корзина"),
        "box" to listOf("ящик"),
        "suitcase" to listOf("чемодан"),
        "toy" to listOf("игрушка")
    )

    // Generic labels such as "product", "tool", "room" and "home" are not
    // reliable enough to produce a supposedly visual product recommendation.
    private val ambiguous = setOf(
        "object", "product", "material", "equipment", "tool", "hardware",
        "home", "room", "indoor", "outdoor", "furniture", "electronic device",
        "machine", "accessory", "design", "building", "structure", "house"
    )

    fun toSearchTerms(label: String): List<String> {
        val normalized = label.lowercase(Locale.ROOT).replace(
            Regex("[^a-zа-яё0-9]+"), " "
        ).trim()
        if (normalized.isBlank() || normalized in ambiguous) return emptyList()
        val padded = " $normalized "
        val found = mappings.filter { (phrase, _) -> " $phrase " in padded }
            .sortedByDescending { it.first.length }
        if (found.isNotEmpty()) {
            // Prefer exact multiword objects and exclude generic submatches,
            // e.g. "paint roller" must not become "paint" and "roller".
            val multiword = found.filter { ' ' in it.first }
            return (if (multiword.isNotEmpty()) multiword else found)
                .flatMap { it.second }.distinct().take(5)
        }
        return if (normalized.any { it in 'а'..'я' || it == 'ё' }) listOf(normalized)
            else emptyList()
    }
}
