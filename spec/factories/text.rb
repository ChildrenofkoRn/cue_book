FactoryBot.define do
  factory :text, class: String do
    skip_create

    samples =
      [
        'The Prodigy - Your Love [Original Mix] #',
        'Jóhann Jóhannsson - Sicario: Original Motion Picture Soundtrack #',
        'Nobuo Uematsu - Sairin: Kata Tsubasa no Tenshi / Advent: One-Winged Angel #',
      ]

    initialize_with { samples.sample }
  end
end
