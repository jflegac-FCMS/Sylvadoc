# Guide de Migration Next.js vers Nuxt.js - FI9

Ce document définit les règles et procédures pour migrer l'application **fi9-front** (Next.js) vers **fi9-front-nuxt** (Nuxt.js).

---

## Table des matières

1. [Règles de transformation générales](#règles-de-transformation-générales)
2. [Structure des dossiers](#structure-des-dossiers)
3. [Transformation des pages](#transformation-des-pages)
4. [Transformation des composants](#transformation-des-composants)
5. [Transformation des styles](#transformation-des-styles)
6. [Transformation des hooks et logique](#transformation-des-hooks-et-logique)
7. [Transformation des layouts/skeletons](#transformation-des-layoutsskeletons)
8. [Checklist de migration](#checklist-de-migration)

---

## Règles de transformation générales

### Principes fondamentaux

1. **Extensions de fichiers** : [.jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/404.jsx) → [.vue](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app/app.vue)
2. **Imports** : Remplacer les alias `@/` par `~/` (convention Nuxt)
3. **useEffect** : Transformer en composables Nuxt (`onMounted`, `watch`, etc.)
4. **CSS Modules** : Transformer en CSS scopé avec nesting et layers
5. **Layouts** : Les skeletons Next.js deviennent des layouts Nuxt
6. **Data Fetching** : [getServerSideProps](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx#170-221) → `useFetch` ou `useAsyncData`
7. **Router** : `next/router` → `useRouter()` de Nuxt
8. **Head/Meta** : `next/head` → `useHead()` ou `useSeoMeta()`

---

## Structure des dossiers

### Next.js (fi9-front)
```
fi9-front/
├── pages/
│   └── [classifiedType]/
│       └── [listSearch].jsx
├── components/
├── page-fragments/
│   └── list/
│       ├── skeletons/
│       │   ├── list-skeleton.jsx
│       │   └── list-skeleton.module.scss
│       ├── ListTitle/
│       ├── Sortbar/
│       └── ...
├── styles/
└── utils/
```

### Nuxt.js (fi9-front-nuxt)
```
fi9-front-nuxt/
├── app/
│   ├── pages/
│   │   └── [classifiedType]/
│   │       └── [listSearch].vue
│   ├── components/
│   │   └── list/
│   │       ├── ListTitle.vue
│   │       ├── Sortbar.vue
│   │       └── ...
│   ├── layouts/
│   │   └── list-skeleton.vue
│   ├── composables/
│   │   ├── useListTracking.ts
│   │   ├── useListMap.ts
│   │   └── useAlertContext.ts
│   └── assets/
│       └── styles/
```

---

## Transformation des pages

### Exemple : `[listSearch].jsx` → `[listSearch].vue`

#### Avant (Next.js)
```jsx
import Head from 'next/head';
import React from 'react';

function List({ canonicalUrl, listData, adKvs, nettingLinks }) {
    const pathname = useTraditionalPathname();
    const { search, exactLoc } = useSearchContext();
    
    React.useEffect(() => {
        // Logic
    }, [listData]);
    
    return (
        <>
            <Head>
                <title>{metaTitle}</title>
                <link rel="canonical" href={canonicalUrl} />
            </Head>
            <ListSkeleton listData={listData} />
        </>
    );
}

export async function getServerSideProps(ctx) {
    const search = parseUrl(ctx.resolvedUrl, ctx.query);
    const listData = await fetchListItems(search);
    
    return {
        props: {
            listData,
            canonicalUrl: buildListCanonical(search)
        }
    };
}

export default List;
```

#### Après (Nuxt.js)
```vue
<script setup lang="ts">
import { parseUrl } from '~/seo/seo-listurl-codec'
import { buildListCanonical } from '~/utils/html-head.utils'
import { buildListSeoTitle } from '~/seo/seo-title'

const route = useRoute()
const router = useRouter()

// Data fetching côté serveur
const { data: listData } = await useAsyncData('list-data', async () => {
  const search = parseUrl(route.fullPath, route.query)
  return await fetchListItems(search)
})

// Computed values
const canonicalUrl = computed(() => buildListCanonical(search.value))
const metaTitle = computed(() => buildListSeoTitle(search.value, exactLoc.value, listData.value?.exactResultsCounter))

// SEO Meta tags
useHead({
  title: metaTitle,
  link: [
    { rel: 'canonical', href: canonicalUrl }
  ]
})

// Tracking avec composable
useListTracking(listData)
</script>

<template>
  <NuxtLayout name="list-skeleton" :list-data="listData">
    <!-- Contenu spécifique à la page si nécessaire -->
  </NuxtLayout>
</template>
```

### Règles de transformation des pages

| Next.js | Nuxt.js | Notes |
|---------|---------|-------|
| `export default function Page()` | `<script setup>` | Composition API obligatoire |
| [getServerSideProps](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx#170-221) | `useAsyncData` ou `useFetch` | Data fetching serveur |
| `useRouter()` from next/router | `useRouter()` from Nuxt | API différente |
| `<Head>` component | `useHead()` composable | Dans `<script setup>` |
| `React.useState` | [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151) ou `reactive()` | Réactivité Vue |
| `React.useEffect` | Voir section Composables | Multiples options |
| `React.useMemo` | `computed()` | Valeurs calculées |
| `React.useCallback` | Fonctions normales | Pas nécessaire en Vue |

---

## Transformation des composants

### Exemple : Composant avec CSS Module

#### Avant (Next.js)
```jsx
// components/ListTitle/list-title.jsx
import React from 'react';
import styles from './list-title.module.scss';

function ListTitle({ mainText, resultCount }) {
    return (
        <div className={styles.container}>
            <h1 className={styles.title}>{mainText}</h1>
            <span className={styles.count}>{resultCount} résultats</span>
        </div>
    );
}

export default ListTitle;
```

```scss
// components/ListTitle/list-title.module.scss
.container {
    display: flex;
    justify-content: space-between;
    padding: 20px;
}

.title {
    font-size: 24px;
    font-weight: bold;
}

.count {
    color: #666;
}
```

#### Après (Nuxt.js)
```vue
<!-- components/list/ListTitle.vue -->
<script setup lang="ts">
interface Props {
  mainText: string
  resultCount: number
}

defineProps<Props>()
</script>

<template>
  <div class="container">
    <h1 class="title">{{ mainText }}</h1>
    <span class="count">{{ resultCount }} résultats</span>
  </div>
</template>

<style scoped>
@layer components {
  .container {
    display: flex;
    justify-content: space-between;
    padding: 20px;
  }

  .title {
    font-size: 24px;
    font-weight: bold;
  }

  .count {
    color: #666;
  }
}
</style>
```

### Règles de transformation des composants

1. **Nommage** : PascalCase pour les fichiers [.vue](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app/app.vue)
2. **Props** : Utiliser `defineProps<T>()` avec TypeScript
3. **Emits** : Utiliser `defineEmits<T>()`
4. **Refs** : Utiliser [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151) au lieu de `React.useRef()`
5. **Conditional rendering** : `v-if` au lieu de `{condition && <Component />}`
6. **Lists** : `v-for` au lieu de `.map()`

---

## Transformation des styles

### Règle 1 : CSS Modules → CSS Scopé

#### Avant
```scss
// component.module.scss
.wrapper {
    padding: 20px;
}

.wrapper .item {
    margin: 10px;
}

.wrapper .item:hover {
    background: #f0f0f0;
}
```

#### Après
```vue
<style scoped>
@layer components {
  .wrapper {
    padding: 20px;
    
    .item {
      margin: 10px;
      
      &:hover {
        background: #f0f0f0;
      }
    }
  }
}
</style>
```

### Règle 2 : Utilisation des CSS Layers

Les CSS layers permettent de contrôler la cascade CSS :

```vue
<style scoped>
/* Layer pour les variables/tokens */
@layer tokens {
  .component {
    --primary-color: #007bff;
    --spacing: 1rem;
  }
}

/* Layer pour les composants */
@layer components {
  .component {
    color: var(--primary-color);
    padding: var(--spacing);
    
    /* CSS Nesting */
    .child {
      margin: calc(var(--spacing) / 2);
      
      &:hover {
        opacity: 0.8;
      }
    }
  }
}

/* Layer pour les utilitaires */
@layer utilities {
  .hide-on-mobile {
    @media (max-width: 768px) {
      display: none;
    }
  }
}
</style>
```

### Règle 3 : CSS Nesting

Utiliser le nesting natif CSS (supporté nativement) :

```css
.parent {
  color: blue;
  
  /* Nesting de sélecteurs */
  .child {
    color: red;
  }
  
  /* Nesting avec & */
  &:hover {
    color: green;
  }
  
  /* Nesting avec media queries */
  @media (min-width: 768px) {
    font-size: 18px;
  }
  
  /* Nesting complexe */
  &.active {
    .icon {
      transform: rotate(90deg);
    }
  }
}
```

### Règle 4 : Classnames dynamiques

#### Avant (Next.js)
```jsx
import cn from 'classnames';
import styles from './component.module.scss';

<div className={cn(styles.wrapper, { [styles.active]: isActive })}>
```

#### Après (Nuxt.js)
```vue
<div :class="['wrapper', { active: isActive }]">
<!-- ou -->
<div :class="{ wrapper: true, active: isActive }">
```

---

## Transformation des hooks et logique

### useEffect → Composables Nuxt

#### Cas 1 : useEffect au montage (componentDidMount)

**Avant**
```jsx
React.useEffect(() => {
    console.log('Component mounted');
    // Cleanup
    return () => {
        console.log('Component unmounted');
    };
}, []);
```

**Après**
```ts
onMounted(() => {
    console.log('Component mounted')
})

onUnmounted(() => {
    console.log('Component unmounted')
})
```

#### Cas 2 : useEffect avec dépendances

**Avant**
```jsx
React.useEffect(() => {
    if (!listData) return;
    
    // Tracking logic
    hitTags(GA_EVENTS.affichage_annonce, { ... });
}, [listData]);
```

**Après - Option 1 : watch**
```ts
watch(() => listData.value, (newData) => {
  if (!newData) return
  
  // Tracking logic
  hitTags(GA_EVENTS.affichage_annonce, { ... })
})
```

**Après - Option 2 : Composable dédié**
```ts
// composables/useListTracking.ts
export function useListTracking(listData: Ref<ListData>) {
  watch(listData, (data) => {
    if (!data) return
    
    if (data.programs?.filter(p => p.isPolePosition).length > 0) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_pole_po',
        gaCreative: 'pole_position'
      })
    }
    
    // ... autres trackings
  }, { immediate: true })
}

// Dans le composant
useListTracking(listData)
```

#### Cas 3 : useEffect avec event listeners

**Avant**
```jsx
React.useEffect(() => {
    const handleScroll = () => {
        // Logic
    };
    
    window.addEventListener('scroll', handleScroll);
    
    return () => {
        window.removeEventListener('scroll', handleScroll);
    };
}, [dependency]);
```

**Après**
```ts
// composables/useScrollListener.ts
export function useScrollListener(callback: () => void, dependency?: Ref) {
  const handleScroll = () => {
    callback()
  }
  
  onMounted(() => {
    window.addEventListener('scroll', handleScroll)
  })
  
  onUnmounted(() => {
    window.removeEventListener('scroll', handleScroll)
  })
  
  if (dependency) {
    watch(dependency, () => {
      // Re-setup if needed
    })
  }
}
```

### Autres transformations de hooks

| React Hook | Vue/Nuxt Équivalent | Notes |
|------------|---------------------|-------|
| `useState` | [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151) | Réactivité simple |
| `useMemo` | `computed()` | Valeurs calculées |
| `useCallback` | Fonction normale | Pas nécessaire |
| `useContext` | `provide/inject` ou composable | Partage de state |
| `useRef` | [ref()](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx#138-151) ou `shallowRef()` | Références DOM/valeurs |
| `useReducer` | `reactive()` + fonctions | Ou Pinia store |

### Création de composables personnalisés

#### Exemple : useAlertContext

**Avant (Next.js - Context)**
```jsx
// utils/alert.utils.js
export const AlertContext = React.createContext();

// Dans le composant
const [alertCreated, setAlertCreated] = React.useState(false);
const alertContextValue = React.useMemo(
    () => ({ alertCreated, setAlertCreated, search: {} }), 
    [alertCreated]
);

<AlertContext.Provider value={alertContextValue}>
    {children}
</AlertContext.Provider>
```

**Après (Nuxt.js - Composable)**
```ts
// composables/useAlertContext.ts
export function useAlertContext() {
  const alertCreated = ref(false)
  const search = ref({})
  
  const setAlertCreated = (value: boolean) => {
    alertCreated.value = value
  }
  
  return {
    alertCreated: readonly(alertCreated),
    setAlertCreated,
    search: readonly(search)
  }
}

// Dans le composant
const { alertCreated, setAlertCreated } = useAlertContext()
```

#### Exemple : useMapDisplay

**Avant**
```jsx
const [isMapDisplayed, setIsMapDisplayed] = React.useState(false);

React.useEffect(() => {
    if (layout === LAYOUTS.DESKTOP && 
        window.localStorage.getItem(DISPLAY_MAP_STORAGE_KEY) === 'true') {
        setIsMapDisplayed(true);
    }
}, [layout]);

const handleMapDisplayChange = React.useCallback(newValue => {
    setIsMapDisplayed(newValue);
    window.localStorage.setItem(DISPLAY_MAP_STORAGE_KEY, newValue);
}, []);
```

**Après**
```ts
// composables/useMapDisplay.ts
export function useMapDisplay(layout: Ref<string>) {
  const isMapDisplayed = ref(false)
  const DISPLAY_MAP_STORAGE_KEY = 'FI9_MAP_DISPLAYED'
  
  // Initialisation depuis localStorage
  onMounted(() => {
    if (layout.value === LAYOUTS.DESKTOP) {
      const stored = localStorage.getItem(DISPLAY_MAP_STORAGE_KEY)
      isMapDisplayed.value = stored === 'true'
    }
  })
  
  // Watch layout changes
  watch(layout, (newLayout) => {
    if (newLayout === LAYOUTS.DESKTOP) {
      const stored = localStorage.getItem(DISPLAY_MAP_STORAGE_KEY)
      isMapDisplayed.value = stored === 'true'
    }
  })
  
  const handleMapDisplayChange = (newValue: boolean) => {
    isMapDisplayed.value = newValue
    localStorage.setItem(DISPLAY_MAP_STORAGE_KEY, String(newValue))
  }
  
  const openMap = () => {
    handleMapDisplayChange(true)
  }
  
  return {
    isMapDisplayed: readonly(isMapDisplayed),
    handleMapDisplayChange,
    openMap
  }
}
```

---

## Transformation des layouts/skeletons

Les **skeletons** Next.js (comme [list-skeleton.jsx](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/skeletons/list-skeleton.jsx)) deviennent des **layouts** Nuxt.

### Avant (Next.js)
```jsx
// page-fragments/list/skeletons/list-skeleton.jsx
function ListSkeleton({ listData, nettingLinks, isFromEmail }) {
    // Beaucoup de logique...
    
    return (
        <div>
            <SearchBar ref={searchBarRef} />
            <div className={styles.wrapper}>
                {/* Structure complexe */}
            </div>
        </div>
    );
}
```

### Après (Nuxt.js)
```vue
<!-- layouts/list-skeleton.vue -->
<script setup lang="ts">
interface Props {
  listData?: any
  nettingLinks?: any
  isFromEmail?: boolean
}

const props = defineProps<Props>()

const route = useRoute()
const search = useSearchObject()
const exactLoc = useSearchExactLoc()
const layout = useScreenLayout()

// Composables pour séparer la logique
const { isMapDisplayed, handleMapDisplayChange, openMap } = useMapDisplay(layout)
const { hoveredItemId, handleMouseEnterItem, handleMouseLeaveItem } = useListHover()
const mapPosition = useMapPosition(isMapDisplayed, layout)

// Alert context
const { alertCreated, setAlertCreated } = useAlertContext()

// Tracking
useListTracking(toRef(props, 'listData'))

// Computed values
const totalCount = computed(() => props.listData?.counter || 0)
const baseCount = computed(() => props.listData?.exactResultsCounter || 0)
const h1Text = computed(() => buildListSeoH1(search.value, exactLoc.value))
</script>

<template>
  <div>
    <SearchBar ref="searchBarRef" />
    <div :class="['wrapper', { 'map-open': isMapDisplayed }]">
      <div :class="['page-container', { 'map-open': isMapDisplayed }]">
        <div class="main-container">
          <!-- Slot pour le contenu de la page -->
          <slot />
          
          <!-- Contenu du layout -->
          <Breadcrumbs :page="PAGE.LISTE" :breadcrumbs-data="breadcrumbsData" />
          <ListTitle :main-text="h1Text" :result-count="totalCount" />
          
          <!-- ... reste du template -->
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@layer layout {
  .wrapper {
    display: flex;
    flex-direction: column;
    
    &.map-open {
      .page-container {
        width: 50%;
      }
    }
  }
  
  .page-container {
    width: 100%;
    transition: width 0.3s ease;
  }
  
  .main-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
  }
}
</style>
```

### Utilisation du layout dans une page

```vue
<!-- pages/[classifiedType]/[listSearch].vue -->
<script setup lang="ts">
definePageMeta({
  layout: 'list-skeleton'
})

const { data: listData } = await useAsyncData('list', () => fetchListItems())
</script>

<template>
  <NuxtLayout :list-data="listData">
    <!-- Contenu spécifique injecté dans le slot du layout -->
  </NuxtLayout>
</template>
```

---

## Checklist de migration

### Phase 1 : Préparation

- [ ] Analyser la page `[listSearch].jsx` et identifier tous les composants utilisés
- [ ] Lister tous les fichiers [.module.scss](file:///home/sylvadoc/Documents/FI9/fi9-front/page-fragments/list/seo-top-content.module.scss) associés
- [ ] Identifier tous les `useEffect` et leur logique
- [ ] Identifier tous les contextes React utilisés
- [ ] Créer la structure de dossiers dans [fi9-front-nuxt/app](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app)

### Phase 2 : Migration des utilitaires

- [ ] Migrer les fonctions utilitaires (sans dépendances React)
- [ ] Adapter les imports (`@/` → `~/`)
- [ ] Créer les types TypeScript si nécessaire

### Phase 3 : Migration des composables

- [ ] Créer `composables/useListTracking.ts`
- [ ] Créer `composables/useMapDisplay.ts`
- [ ] Créer `composables/useAlertContext.ts`
- [ ] Créer `composables/useListHover.ts`
- [ ] Créer `composables/useMapPosition.ts`
- [ ] Créer `composables/useSearchContext.ts`

### Phase 4 : Migration des composants

Pour chaque composant :
- [ ] Créer le fichier [.vue](file:///home/sylvadoc/Documents/FI9/fi9-front-nuxt/app/app.vue) dans `components/list/`
- [ ] Transformer le JSX en template Vue
- [ ] Convertir les props avec `defineProps<T>()`
- [ ] Convertir les events avec `defineEmits<T>()`
- [ ] Transformer le CSS module en CSS scopé
- [ ] Appliquer le CSS nesting
- [ ] Organiser avec CSS layers
- [ ] Tester le composant isolément

Composants à migrer :
- [ ] `ListTitle`
- [ ] `Sortbar`
- [ ] `SidebarList`
- [ ] `ListAnnonces`
- [ ] `IndicatorsSection`
- [ ] `SeoDescription`
- [ ] `SeoTextGaps`
- [ ] `DonePrograms`
- [ ] `TopPromoters`
- [ ] `AlertButton`
- [ ] `AlertForm`
- [ ] `AlertToaster`

### Phase 5 : Migration du layout

- [ ] Créer `layouts/list-skeleton.vue`
- [ ] Migrer la structure HTML
- [ ] Intégrer les composables
- [ ] Transformer les styles
- [ ] Définir les slots appropriés
- [ ] Tester le layout

### Phase 6 : Migration de la page

- [ ] Créer `pages/[classifiedType]/[listSearch].vue`
- [ ] Transformer [getServerSideProps](file:///home/sylvadoc/Documents/FI9/fi9-front/pages/%5BclassifiedType%5D/%5BlistSearch%5D.jsx#170-221) en `useAsyncData`
- [ ] Migrer la logique de data fetching
- [ ] Configurer `useHead()` pour le SEO
- [ ] Connecter au layout
- [ ] Tester la page complète

### Phase 7 : Tests et validation

- [ ] Vérifier le rendu côté serveur (SSR)
- [ ] Vérifier l'hydratation
- [ ] Tester la navigation
- [ ] Vérifier les meta tags SEO
- [ ] Tester le responsive
- [ ] Vérifier les performances
- [ ] Valider l'accessibilité
- [ ] Tester le tracking analytics

---

## Exemples de code complets

### Composable complet : useListTracking

```ts
// composables/useListTracking.ts
import type { Ref } from 'vue'
import { watch } from 'vue'
import { GA_EVENTS, hitTags } from '~/utils/analytics/tracking-tags.utils'

export function useListTracking(listData: Ref<any>) {
  watch(listData, (data) => {
    if (!data) return
    
    // Pole position tracking
    if (data.programs?.filter((program: any) => program.isPolePosition).length > 0) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_pole_po',
        gaCreative: 'pole_position'
      })
    }
    
    // Top classified tracking
    const topClassified = data.programs?.find((program: any) => program.isTopClassified)
    if (topClassified) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_a_la_une',
        gaCreative: 'a_la_une',
        gaName: `${topClassified.promoterName}_${topClassified.promoterID}`,
        gaPosition: topClassified.localisation?.postalCode,
        promoGA_id: topClassified.id
      })
    }
    
    // Much leads tracking
    const programMuchLeads = data.programs?.find((program: any) => program.isMuchLeads)
    if (programMuchLeads) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_annonce_haut_rdt',
        gaPosition: programMuchLeads.localisation?.postalCode,
        gaCreative: 'haut_rdt',
        gaName: `${programMuchLeads.promoterName}_${programMuchLeads.promoterID}`,
        promoGA_id: programMuchLeads.id
      })
    }
    
    // Few lead tracking
    const programFewLead = data.programs?.find((program: any) => program.isFewLead)
    if (programFewLead) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_annonce_1_3_rdt',
        gaCreative: '1_3_rdt'
      })
    }
    
    // Top clients tracking
    if (data.programs?.some?.((prog: any) => prog.isTopClients)) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_top_client',
        gaCreative: 'top_client'
      })
    }
    
    // Expanded criteria tracking
    if (data.programs?.find((program: any) => program.criteriasExpanded)) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_annonce_elargi_recherche',
        gaCreative: 'elargi_recherche',
        promoGA_id: 'ga_promo_impression'
      })
    }
  }, { immediate: true })
}
```

### Composant complet : Sortbar

```vue
<!-- components/list/Sortbar.vue -->
<script setup lang="ts">
interface Props {
  sortType?: string
  isMapDisplayed: boolean
}

interface Emits {
  (e: 'change-select', event: Event): void
  (e: 'map-display-change', value: boolean): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const handleSortChange = (event: Event) => {
  emit('change-select', event)
}

const toggleMap = () => {
  emit('map-display-change', !props.isMapDisplayed)
}
</script>

<template>
  <div class="sortbar">
    <div class="sort-controls">
      <label for="sort-select">Trier par :</label>
      <select 
        id="sort-select"
        :value="sortType"
        @change="handleSortChange"
        class="sort-select"
      >
        <option value="pertinence">Pertinence</option>
        <option value="prix-croissant">Prix croissant</option>
        <option value="prix-decroissant">Prix décroissant</option>
        <option value="date">Plus récent</option>
      </select>
    </div>
    
    <button 
      class="map-toggle"
      :class="{ active: isMapDisplayed }"
      @click="toggleMap"
    >
      <span class="icon">📍</span>
      {{ isMapDisplayed ? 'Masquer' : 'Afficher' }} la carte
    </button>
  </div>
</template>

<style scoped>
@layer components {
  .sortbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    
    @media (max-width: 768px) {
      flex-direction: column;
      gap: 1rem;
    }
  }
  
  .sort-controls {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    
    label {
      font-weight: 500;
      color: #333;
    }
  }
  
  .sort-select {
    padding: 0.5rem 1rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    background: white;
    cursor: pointer;
    
    &:hover {
      border-color: #007bff;
    }
    
    &:focus {
      outline: none;
      border-color: #007bff;
      box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
    }
  }
  
  .map-toggle {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    background: white;
    cursor: pointer;
    transition: all 0.2s;
    
    &:hover {
      background: #f8f9fa;
      border-color: #007bff;
    }
    
    &.active {
      background: #007bff;
      color: white;
      border-color: #007bff;
      
      .icon {
        filter: brightness(0) invert(1);
      }
    }
  }
  
  .icon {
    font-size: 1.2rem;
  }
}
</style>
```

---

## Ressources et références

### Documentation officielle
- [Nuxt 3 Documentation](https://nuxt.com/docs)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)
- [CSS Nesting](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_nesting)
- [CSS Cascade Layers](https://developer.mozilla.org/en-US/docs/Web/CSS/@layer)

### Outils utiles
- [Nuxt DevTools](https://devtools.nuxt.com/)
- [Vue DevTools](https://devtools.vuejs.org/)
- [TypeScript](https://www.typescriptlang.org/)

---

## Notes importantes

> [!IMPORTANT]
> - Toujours tester le SSR (Server-Side Rendering) après chaque migration
> - Vérifier l'hydratation pour éviter les erreurs de mismatch
> - Utiliser TypeScript pour une meilleure maintenabilité

> [!WARNING]
> - Les refs Vue ne sont pas les mêmes que React refs
> - `watch` ne s'exécute pas immédiatement par défaut (utiliser `{ immediate: true }`)
> - Les CSS layers ont un ordre de priorité spécifique

> [!TIP]
> - Créer des composables réutilisables pour la logique commune
> - Utiliser `computed()` plutôt que `watch` quand c'est possible
> - Préférer `useFetch` à `useAsyncData` pour les appels API simples

---

## Ordre de migration recommandé

1. **Utilitaires et helpers** (pas de dépendances React/Vue)
2. **Composables** (logique métier réutilisable)
3. **Composants simples** (sans enfants, peu de logique)
4. **Composants complexes** (avec beaucoup de logique)
5. **Layouts** (structure de page)
6. **Pages** (assemblage final)

Cette approche bottom-up garantit que toutes les dépendances sont disponibles lors de la migration de chaque niveau.
