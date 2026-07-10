package cc.u_0.jiavva;

import java.util.Locale;
import java.util.Objects;

/**
 * Small utility entry point for the Jiavva package.
 */
public final class Jiavva {
    /**
     * Maven Central coordinates for this artifact.
     */
    public static final String COORDINATES = "cc.u-0:jiavva";

    private Jiavva() {
        throw new AssertionError("No Jiavva instances");
    }

    /**
     * Creates a friendly default greeting.
     *
     * @return a greeting for the world
     */
    public static String hello() {
        return hello("world");
    }

    /**
     * Creates a friendly greeting for a name.
     *
     * @param name target name; blank names fall back to {@code world}
     * @return a greeting
     */
    public static String hello(String name) {
        String target = cleanName(name);
        return "jiavva says hello to " + target + ".";
    }

    /**
     * Creates a stable lowercase marker with a {@code jiavva:} prefix.
     *
     * @param value text to normalize
     * @return normalized marker
     */
    public static String marker(String value) {
        return "jiavva:" + slug(value);
    }

    /**
     * Converts text into a simple lowercase slug.
     *
     * @param value text to normalize
     * @return a slug, or {@code jiavva} when the input has no usable characters
     */
    public static String slug(String value) {
        String normalized = Objects.requireNonNull(value, "value")
                .trim()
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("(^-|-$)", "");
        return normalized.isEmpty() ? "jiavva" : normalized;
    }

    private static String cleanName(String name) {
        if (name == null || name.isBlank()) {
            return "world";
        }
        return name.trim();
    }
}

