FactoryBot.define do
  factory :texts_ext, class: Hash do
    skip_create

      extended_strings = [
        '',
        '1965',
        '\'Ф"антасти"ка\'',
        '\'Sur"veilla"nce\'',
        '"Ф"антаст\'и"ка"',
        '"Sur"veill\'a"nce"',
        'Ф"антаст\'и\'"ка',
        'Sur"veill\'a\'"nce',
        '"Sur"vei;ll.\'a:\'(")n\/ce*"',
        '"Target"',
        'Alejandro\'s Song',
        'Jóhann Jóhannsson',
        '"Лавкрафт - Сомнамбулический поиск неведомого Кадата.wav"',
      ]
      valid_parse = [
        '',
        '1965',
        'Ф"антасти"ка',
        'Sur"veilla"nce',
        'Ф"антаст\'и"ка',
        'Sur"veill\'a"nce',
        'Ф"антаст\'и\'"ка',
        'Sur"veill\'a\'"nce',
        'Sur"vei;ll.\'a:\'(")n\/ce*',
        'Target',
        'Alejandro\'s Song',
        'Jóhann Jóhannsson',
        'Лавкрафт - Сомнамбулический поиск неведомого Кадата.wav',
      ]

    initialize_with { extended_strings.zip(valid_parse).to_h }
  end
end
