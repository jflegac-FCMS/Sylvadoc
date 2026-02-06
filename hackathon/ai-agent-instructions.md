# Instructions pour Agent IA - Migration Next.js → Nuxt.js

> **Destinataire** : Agent IA (Claude, GPT, etc.)  
> **Objectif** : Migrer la page `listSearch.jsx` et ses composants de Next.js vers Nuxt.js  
> **Projet** : fi9-front → fi9-front-nuxt

---

## 🎯 Mission

Migrer la page de liste de recherche (`[listSearch].jsx`) et tous ses composants associés de l'application Next.js vers Nuxt.js en suivant les règles de transformation définies.

---

## 📋 Règles de transformation OBLIGATOIRES

### 1. **useEffect → Composables**

```typescript
// ❌ AVANT (Next.js)
React.useEffect(() => {
  // logique
}, [dependency])

// ✅ APRÈS (Nuxt.js)
watch(() => dependency.value, () => {
  // logique
}, { immediate: true })

// OU créer un composable
// composables/useFeature.ts
export function useFeature(dependency: Ref) {
  watch(dependency, () => {
    // logique
  }, { immediate: true })
}
```

### 2. **CSS Modules → CSS Scopé avec Nesting et Layers**

```vue
<!-- ❌ AVANT (Next.js) -->
<div className={styles.container}>
  <div className={styles.item}>...</div>
</div>

<style module>
.container .item { ... }
</style>

<!-- ✅ APRÈS (Nuxt.js) -->
<div class="container">
  <div class="item">...</div>
</div>

<style scoped>
@layer components {
  .container {
    /* styles */
    
    .item {
      /* CSS nesting natif */
      
      &:hover {
        /* pseudo-classes */
      }
    }
  }
}
</style>
```

### 3. **Skeletons → Layouts**

```vue
<!-- ❌ AVANT : page-fragments/list/skeletons/list-skeleton.jsx -->

<!-- ✅ APRÈS : layouts/list-skeleton.vue -->
<script setup>
// Logique du layout
</script>

<template>
  <div>
    <!-- Structure du layout -->
    <slot /> <!-- Contenu de la page -->
  </div>
</template>
```

---

## 🔧 Transformations techniques

### Imports
```typescript
// ❌ Next.js
import Component from '@/components/Component'

// ✅ Nuxt.js
import Component from '~/components/Component'
```

### Data Fetching
```typescript
// ❌ Next.js
export async function getServerSideProps(ctx) {
  const data = await fetchData()
  return { props: { data } }
}

// ✅ Nuxt.js
const { data } = await useAsyncData('key', () => fetchData())
```

### Router
```typescript
// ❌ Next.js
import { useRouter } from 'next/router'
const router = useRouter()
router.push('/path')

// ✅ Nuxt.js
const router = useRouter()
await navigateTo('/path')
```

### Head/Meta
```typescript
// ❌ Next.js
import Head from 'next/head'
<Head>
  <title>{title}</title>
</Head>

// ✅ Nuxt.js
useHead({
  title: computed(() => title.value)
})
```

### State
```typescript
// ❌ Next.js
const [state, setState] = React.useState(initial)

// ✅ Nuxt.js
const state = ref(initial)
```

### Computed
```typescript
// ❌ Next.js
const value = React.useMemo(() => compute(), [dep])

// ✅ Nuxt.js
const value = computed(() => compute())
```

### Callbacks
```typescript
// ❌ Next.js
const handler = React.useCallback(() => {}, [])

// ✅ Nuxt.js
const handler = () => {} // Pas besoin de useCallback
```

### Context
```typescript
// ❌ Next.js
const MyContext = React.createContext()
<MyContext.Provider value={value}>

// ✅ Nuxt.js
// Option 1: Composable
export function useMyContext() {
  const state = ref()
  return { state }
}

// Option 2: provide/inject
provide('myKey', value)
const value = inject('myKey')
```

---

## 📁 Structure de fichiers

### Fichiers à créer dans [fi9-front-nuxt/app/](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app)

```
pages/
  [classifiedType]/
    [listSearch].vue          ← Page principale

layouts/
  list-skeleton.vue           ← Layout (ancien skeleton)

components/
  list/
    ListTitle.vue
    Sortbar.vue
    SidebarList.vue
    ListAnnonces.vue
    IndicatorsSection.vue
    SeoDescription.vue
    SeoTextGaps.vue
    DonePrograms.vue
    TopPromoters.vue

composables/
  useListTracking.ts          ← Logique de tracking
  useMapDisplay.ts            ← Gestion affichage carte
  useMapPosition.ts           ← Position de la carte
  useListHover.ts             ← Hover sur items
  useAlertContext.ts          ← Context alertes
  useListPagination.ts        ← Pagination
```

---

## 🎬 Plan d'exécution

### Phase 1 : Analyse (OBLIGATOIRE)
1. Lire [/home/sylvadoc/Documents/FI9/fi9-front/pages/[classifiedType]/[listSearch].jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx)
2. Identifier tous les composants importés
3. Identifier tous les `useEffect` et leur logique
4. Lister tous les fichiers [.module.scss](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/seo-top-content.module.scss)

### Phase 2 : Composables
Pour chaque `useEffect` dans `[listSearch].jsx` :
1. Créer un composable dans `composables/use*.ts`
2. Transformer la logique React en Vue
3. Exporter une fonction réutilisable

**Exemple** :
```typescript
// composables/useListTracking.ts
export function useListTracking(listData: Ref<any>) {
  watch(listData, (data) => {
    if (!data) return
    // Logique de tracking
  }, { immediate: true })
}
```

### Phase 3 : Composants simples
Pour chaque composant dans `page-fragments/list/` :
1. Créer `components/list/ComponentName.vue`
2. Transformer JSX → Template Vue
3. Transformer props : `defineProps<T>()`
4. Transformer events : `defineEmits<T>()`
5. Transformer CSS module → CSS scopé avec layers

**Template de composant** :
```vue
<script setup lang="ts">
interface Props {
  // types
}
interface Emits {
  (e: 'eventName', value: Type): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()
</script>

<template>
  <!-- Vue template -->
</template>

<style scoped>
@layer components {
  /* CSS avec nesting */
}
</style>
```

### Phase 4 : Layout
1. Créer `layouts/list-skeleton.vue`
2. Migrer la logique de [list-skeleton.jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx)
3. Utiliser les composables créés
4. Définir les slots pour le contenu

### Phase 5 : Page principale
1. Créer `pages/[classifiedType]/[listSearch].vue`
2. Transformer [getServerSideProps](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx#170-221) → `useAsyncData`
3. Configurer `useHead()` pour SEO
4. Utiliser le layout avec `definePageMeta`

### Phase 6 : Validation
- [ ] Vérifier SSR (pas d'erreurs serveur)
- [ ] Vérifier hydratation (pas de mismatch)
- [ ] Tester navigation
- [ ] Vérifier meta tags
- [ ] Tester responsive

---

## 🚨 Règles STRICTES

### CSS Layers - Ordre de priorité
```css
/* Toujours dans cet ordre */
@layer tokens {
  /* Variables CSS */
}

@layer components {
  /* Composants */
}

@layer utilities {
  /* Utilitaires */
}
```

### CSS Nesting - Syntaxe
```css
.parent {
  color: blue;
  
  /* ✅ Correct */
  .child { }
  &:hover { }
  &.modifier { }
  
  /* ❌ Incorrect */
  > .child { } /* Pas supporté partout */
}
```

### Composables - Naming
```typescript
// ✅ Correct
export function useFeatureName() { }

// ❌ Incorrect
export function featureName() { }
export const useFeature = () => { }
```

### Refs - Réactivité
```typescript
// ✅ Correct
const count = ref(0)
count.value++

// ❌ Incorrect
const count = ref(0)
count++ // Ne fonctionne pas
```

### Watch - Immediate
```typescript
// ✅ Pour remplacer useEffect avec deps
watch(dep, () => {
  // logique
}, { immediate: true })

// ❌ Sans immediate, ne s'exécute pas au montage
watch(dep, () => {
  // logique
})
```

---

## 📝 Template de page complète

```vue
<script setup lang="ts">
// 1. Imports
import { computed, ref } from 'vue'

// 2. definePageMeta
definePageMeta({
  layout: 'list-skeleton',
  validate: async (route) => {
    return true // validation
  }
})

// 3. Route & Router
const route = useRoute()
const router = useRouter()

// 4. Data Fetching
const { data: myData } = await useAsyncData('key', async () => {
  return await fetchData()
})

// 5. Computed
const computed Value = computed(() => myData.value?.property)

// 6. Composables
useMyComposable(myData)

// 7. SEO
useHead({
  title: computedValue,
  meta: [
    { name: 'description', content: computedValue }
  ]
})

// 8. Provide (si nécessaire)
provide('key', value)
</script>

<template>
  <NuxtLayout :prop="value">
    <!-- Contenu -->
  </NuxtLayout>
</template>
```

---

## 📝 Template de composable

```typescript
import type { Ref } from 'vue'
import { ref, watch, onMounted, onUnmounted, computed } from 'vue'

export function useFeatureName(dependency: Ref<any>) {
  // State
  const state = ref(initialValue)
  
  // Computed
  const computedValue = computed(() => state.value * 2)
  
  // Watch
  watch(dependency, (newValue) => {
    // Logique
  }, { immediate: true })
  
  // Lifecycle
  onMounted(() => {
    // Setup
  })
  
  onUnmounted(() => {
    // Cleanup
  })
  
  // Methods
  const method = () => {
    // Logique
  }
  
  // Return
  return {
    state: readonly(state),
    computedValue,
    method
  }
}
```

---

## 🎯 Checklist par fichier

Pour chaque fichier migré :

- [ ] ✅ Extension changée ([.jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/404.jsx) → [.vue](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app/app.vue))
- [ ] ✅ Imports mis à jour (`@/` → `~/`)
- [ ] ✅ Props typées avec `defineProps<T>()`
- [ ] ✅ Events typés avec `defineEmits<T>()`
- [ ] ✅ `useEffect` transformés en `watch` ou composables
- [ ] ✅ `useState` → [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151)
- [ ] ✅ `useMemo` → `computed()`
- [ ] ✅ `useCallback` supprimés (pas nécessaires)
- [ ] ✅ CSS module → CSS scopé
- [ ] ✅ CSS nesting appliqué
- [ ] ✅ CSS layers utilisés
- [ ] ✅ Pas d'erreurs TypeScript
- [ ] ✅ Pas d'erreurs de lint
- [ ] ✅ Testé en dev

---

## 🔍 Debugging

### Erreur d'hydratation
```
Hydration mismatch
```
**Cause** : Différence entre SSR et client  
**Solution** : Utiliser `onMounted` pour le code client-only

```vue
<script setup>
const clientOnly = ref(false)
onMounted(() => {
  clientOnly.value = true
})
</script>

<template>
  <div v-if="clientOnly">
    <!-- Contenu client-only -->
  </div>
</template>
```

### Ref non réactive
```typescript
// ❌ Problème
const data = ref({ count: 0 })
data.count++ // Ne déclenche pas de réactivité

// ✅ Solution
data.value.count++
```

### Watch ne s'exécute pas
```typescript
// ❌ Problème
watch(dep, () => {
  // Ne s'exécute pas au montage
})

// ✅ Solution
watch(dep, () => {
  // S'exécute au montage et aux changements
}, { immediate: true })
```

---

## 📚 Ressources

- [Guide de migration complet](./migration-next-to-nuxt.md)
- [Exemples pratiques](./migration-examples-listsearch.md)
- [Nuxt 3 Docs](https://nuxt.com/docs)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)

---

## ✅ Critères de succès

La migration est réussie si :

1. ✅ La page se charge sans erreur en SSR
2. ✅ Pas d'erreurs d'hydratation
3. ✅ Les meta tags SEO sont identiques
4. ✅ Le tracking analytics fonctionne
5. ✅ Les styles sont identiques visuellement
6. ✅ Toutes les interactions fonctionnent (carte, tri, pagination)
7. ✅ Les performances sont équivalentes ou meilleures
8. ✅ Le code est propre et typé (TypeScript)

---

## 🚀 Commandes utiles

```bash
# Démarrer le serveur de dev
cd fi9-front-nuxt
npm run dev

# Build de production
npm run build

# Analyser le bundle
npm run analyze

# Linter
npm run lint

# Type checking
npm run typecheck
```

---

## 💡 Conseils pour l'agent IA

1. **Lire d'abord** : Toujours lire le fichier source complet avant de migrer
2. **Identifier les patterns** : Repérer les useEffect, useState, etc.
3. **Créer les composables d'abord** : Ils seront réutilisés partout
4. **Tester au fur et à mesure** : Ne pas tout migrer d'un coup
5. **Respecter les types** : Utiliser TypeScript strictement
6. **Documenter** : Ajouter des commentaires pour les transformations complexes
7. **Vérifier le SSR** : Toujours tester en mode production

---

## 🎯 Exemple concret : Migration d'un useEffect

### Source (Next.js)
```jsx
React.useEffect(() => {
    if (!listData) return;
    
    if (listData.programs?.filter(p => p.isPolePosition).length > 0) {
        hitTags(GA_EVENTS.affichage_annonce, {
            label: 'liste_pole_po',
            gaCreative: 'pole_position'
        });
    }
}, [listData]);
```

### Cible (Nuxt.js)

**Option 1 : Watch direct**
```vue
<script setup>
watch(() => listData.value, (data) => {
  if (!data) return
  
  if (data.programs?.filter(p => p.isPolePosition).length > 0) {
    hitTags(GA_EVENTS.affichage_annonce, {
      label: 'liste_pole_po',
      gaCreative: 'pole_position'
    })
  }
}, { immediate: true })
</script>
```

**Option 2 : Composable (RECOMMANDÉ)**
```typescript
// composables/useListTracking.ts
export function useListTracking(listData: Ref<any>) {
  watch(listData, (data) => {
    if (!data) return
    
    if (data.programs?.filter(p => p.isPolePosition).length > 0) {
      hitTags(GA_EVENTS.affichage_annonce, {
        label: 'liste_pole_po',
        gaCreative: 'pole_position'
      })
    }
  }, { immediate: true })
}
```

```vue
<script setup>
// Dans le composant
useListTracking(listData)
</script>
```

---

## 🎓 Résumé des transformations

| Concept | Next.js | Nuxt.js |
|---------|---------|---------|
| **Extension** | [.jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/404.jsx) | [.vue](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app/app.vue) |
| **Imports** | `@/` | `~/` |
| **State** | `useState` | [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151) |
| **Computed** | `useMemo` | `computed()` |
| **Effects** | `useEffect` | `watch` / composables |
| **Callbacks** | `useCallback` | Fonction normale |
| **Context** | `createContext` | `provide/inject` ou composable |
| **Data fetch** | [getServerSideProps](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx#170-221) | `useAsyncData` |
| **Router** | `next/router` | `useRouter()` |
| **Head** | `<Head>` | `useHead()` |
| **CSS** | [.module.scss](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/seo-top-content.module.scss) | `<style scoped>` |
| **Layout** | Skeleton component | `layouts/*.vue` |

---

**Bonne migration ! 🚀**
