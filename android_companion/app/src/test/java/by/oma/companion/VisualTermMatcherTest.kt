package by.oma.companion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VisualTermMatcherTest {
    @Test fun identifiesPlumbingFromEnglishLabels() {
        assertEquals(listOf("смеситель"), VisualTermMatcher.toSearchTerms("Faucet"))
        assertEquals(listOf("мойка", "раковина"), VisualTermMatcher.toSearchTerms("Sink"))
    }

    @Test fun choosesPreciseMultiwordObjectOverGenericColorOrPart() {
        assertEquals(listOf("кисть"), VisualTermMatcher.toSearchTerms("Paint Brush"))
        assertEquals(listOf("валик"), VisualTermMatcher.toSearchTerms("Paint Roller"))
        assertEquals(listOf("дрель", "шуруповерт"),
            VisualTermMatcher.toSearchTerms("Cordless Drill"))
    }

    @Test fun rejectsGenericLabelsAndFalseSubstringMatches() {
        assertTrue(VisualTermMatcher.toSearchTerms("Product").isEmpty())
        assertTrue(VisualTermMatcher.toSearchTerms("Hardware").isEmpty())
        assertTrue(VisualTermMatcher.toSearchTerms("Tapestry").isEmpty())
        assertFalse(VisualTermMatcher.toSearchTerms("Ceiling Light").isEmpty())
    }

    @Test fun retainsLocalizedSubject() {
        assertEquals(listOf("смеситель"), VisualTermMatcher.toSearchTerms("Смеситель"))
    }
}
