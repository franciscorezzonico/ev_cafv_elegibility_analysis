# ---------------------------------------------------------------------------- #
### EV BRAND AND CAFV ELEGIBILITY ANALYSIS ###

# Author: Francisco Rezzonico

# Last revised on: August 26, 2026

# Description:
# This script analyzes the relationship between electric vehicle (EV) make and
# Clean Alternative Fuel Vehicle (CAFV) eligibility using Washington State's
# Electric Vehicle Population dataset. The analysis subsets the data to five
# manufacturers—Tesla, Nissan, BMW, Toyota, and Mercedes-Benz—and produces
# univariate frequency summaries, a bivariate contingency table, a chi-square
# test of independence, Cramér's V effect size, a mosaic plot, and a formatted
# summary table.

# The analysis evaluates whether CAFV eligibility status differs significantly
# across the selected EV manufacturers and highlights differences in eligible,
# not eligible, and eligibility-unknown vehicle records.

# ---------------------------------------------------------------------------- #

# Libraries.
library(DescTools)
library(ggplot2)
library(scales)
library(dplyr)
library(janitor)

# Load the Washington State Electric Vehicle Population dataset.
ev <- read.csv("data/electric_vehicle_population_data.csv")

# Inspect available vehicle makes and CAFV eligibility labels before filtering.
str(ev)
sort(unique(ev$Clean.Alternative.Fuel.Vehicle..CAFV..Eligibility))
sort(unique(ev$Make))

# Restrict the analytic sample to the five manufacturers selected for comparison.
selected_makes <- c(
  'TESLA',
  'NISSAN',
  'BMW',
  'TOYOTA',
  'MERCEDES-BENZ'
)

ev_sub <- ev[ev$Make %in% selected_makes, ]

# Preserve the intended manufacturer order across tables and visualizations.
ev_sub$Make <- factor(
  ev_sub$Make,
  levels = selected_makes
)

# Create a concise variable name for repeated use throughout the analysis.
ev_sub$CAFV_Eligibility <-
  ev_sub$Clean.Alternative.Fuel.Vehicle..CAFV..Eligibility

# Summarize the distribution of vehicles across the selected manufacturers.
make_summary <- ev_sub |>
  count(Make, name = "Frequency") |>
  mutate(Percent = round(Frequency / sum(Frequency) * 100, 2))

make_summary

# Summarize the overall distribution of CAFV eligibility records.
cafv_summary <- ev_sub |>
  count(CAFV_Eligibility, name = "Frequency") |>
  mutate(Percent = round(Frequency / sum(Frequency) * 100, 2))

cafv_summary

# Test whether CAFV eligibility status is independent of EV manufacturer.
alpha <- 0.01

ev_tab <- table(
  Make = ev_sub$Make,
  CAFV_Eligibility = ev_sub$CAFV_Eligibility
)

ev_chi <- chisq.test(ev_tab)

ev_chi

# Inspect expected counts to verify the chi-square approximation is appropriate.
ev_chi$expected

# State the inferential decision using the pre-specified 1% significance
# threshold.
if (ev_chi$p.value < alpha) {
  message("Reject H0: EV make and CAFV eligibility are associated.")
} else {
  message("Fail to reject H0: Insufficient evidence of an association.")
}

# Show the make composition within each CAFV eligibility category.
make_within_cafv_pct <- round(prop.table(ev_tab, margin = 2) * 100, digits = 2)

make_within_cafv_pct

# Quantify the strength of the make–CAFV eligibility association.
ev_cramer_v <- CramerV(ev_tab)
cat("Cramér's V:", round(ev_cramer_v, 3), "\n")

# Compare CAFV eligibility profiles within each selected EV manufacturer.
ggplot(ev_sub, aes(x = Make, fill = CAFV_Eligibility)) +
  geom_bar(position = "fill") +
  scale_y_continuous(
    labels = label_percent(),
    expand = c(0, 0)
  ) +
  scale_fill_manual(
    values = c(
      "Clean Alternative Fuel Vehicle Eligible" = "#2E8B57",
      "Eligibility unknown as battery range has not been researched" = "#E69F00",
      "Not eligible due to low battery range" = "#B22222"
    )
  ) +
  labs(
    title = "CAFV Eligibility Distribution by EV Make",
    x = "EV Make",
    y = "Percent of Vehicles Within Make",
    fill = "CAFV Eligibility",
    caption = "Source: Washington State Electric Vehicle Population Data"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1,
    ),
    plot.title = element_text(
      face = "bold",
      hjust = 0.5
    ),
    plot.caption = element_text(hjust = 1),
    plot.caption.position = "plot"
  )

# Report counts and within-make CAFV eligibility percentages in one table.
cafv_by_make_table <- tabyl(
  ev_sub,
  Make,
  CAFV_Eligibility
) |>
  adorn_totals(c("row", "col")) |>
  adorn_percentages("row") |>
  adorn_pct_formatting(digits = 1) |>
  adorn_ns(position = "front")

cafv_by_make_table
