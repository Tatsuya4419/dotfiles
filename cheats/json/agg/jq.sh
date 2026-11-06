jq 'group_by(.g) | map({g: .[0].g, n: length, mean: (map(.x) | add / length)})'
