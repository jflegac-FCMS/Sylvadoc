---
name: sylvadoc-eslint-config
description: ESLint flat config pour formatter et linter le code, avec ESLint et Prettier.
---

# Principes

Une configuration ESLint, tout-en-un, pour formatter et linter le code JavaScript/TypeScript, Vue

# Exemples avec Nuxt

Utiliser les préférences de Nuxt avec des ajustements personnalisés.

```
// @ts-check
import withNuxt from './.nuxt/eslint.config.mjs'
import eslintPluginPrettierRecommended from 'eslint-plugin-prettier/recommended'

export default withNuxt()
    .append(eslintPluginPrettierRecommended)
    .override('nuxt/vue/rules', {
        rules: {
            'vue/html-self-closing': 'off',
            'vue/no-v-html': 'off',
            'vue/no-v-text-v-html-on-component': 'off'
        }
    })
```

# formattage avec Prettier

Exemples de règles de formatage avec `prettier`.

```
const config = {
    semi: false,
    singleQuote: true,
    trailingComma: 'none',
    tabWidth: 4,
    printWidth: 120
}

export default config

```