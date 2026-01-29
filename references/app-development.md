---
name: app-development
description: Les préférences de Sylvadoc pour la confection d'applications web avec Vue, Vite/Nuxt
---

# App Development Preferences

Préférences pour confectionner une application web moderne avec Vue 3, Vite ou Nuxt, et VueUse.

## Stack Overview

| Aspect | Choice                                                                     |
|--------|----------------------------------------------------------------------------|
| Framework | Vue 3 (Composition API)                                                    |
| Build Tool | Vite (SPA) or Nuxt (SSR/SSG)                                               |
| Styling | CSS, CSS Nesting, CSS layers, CSS container queries, CSS custom properties |
| Utilities | VueUse                                                                     |

---

## Framework Selection

| Use Case | Choix      |
|----------|------------|
| SPA, client-only, library playgrounds | Vite + Vue |
| SSR, SSG, SEO-critical, file-based routing, API routes | Nuxt       |

---

## Vue Conventions

| Convention | Préférences                           |
|------------|---------------------------------------|
| Script syntax | Toujours `<script setup lang="ts">`   |
| State | Préférer `shallowRef()` over `ref()`  |
| Objects | Utiliser `ref()`, éviter `reactive()` |

### Props and Emits

Toujours utiliser les interfaces TypeScript pour définir les props et les événements émis.

```vue
<script setup lang="ts">
interface Props {
  title: string
  count?: number
}

interface Emits {
  (e: 'update', value: number): void
  (e: 'close'): void
}

const props = withDefaults(defineProps<Props>(), {
  count: 0,
})

const emit = defineEmits<Emits>()
</script>
```