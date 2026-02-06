# Migration Pratique : Page listSearch.jsx

Ce document fournit des exemples concrets et exécutables pour migrer la page `listSearch.jsx` et ses composants.

---

## Table des matières

1. [Structure cible](#structure-cible)
2. [Migration de la page principale](#migration-de-la-page-principale)
3. [Migration des composables](#migration-des-composables)
4. [Migration du layout list-skeleton](#migration-du-layout-list-skeleton)
5. [Migration des composants](#migration-des-composants)
6. [Scripts de migration](#scripts-de-migration)

---

## Structure cible

```
fi9-front-nuxt/app/
├── pages/
│   └── [classifiedType]/
│       └── [listSearch].vue
├── layouts/
│   └── list-skeleton.vue
├── components/
│   └── list/
│       ├── ListTitle.vue
│       ├── Sortbar.vue
│       ├── SidebarList.vue
│       ├── ListAnnonces.vue
│       ├── IndicatorsSection.vue
│       ├── SeoDescription.vue
│       ├── SeoTextGaps.vue
│       ├── DonePrograms.vue
│       └── TopPromoters.vue
├── composables/
│   ├── useListTracking.ts
│   ├── useMapDisplay.ts
│   ├── useMapPosition.ts
│   ├── useListHover.ts
│   ├── useAlertContext.ts
│   ├── useSearchContext.ts
│   └── useListPagination.ts
└── utils/
    └── (fichiers utilitaires migrés)
```

---

## Migration de la page principale

### Fichier : `pages/[classifiedType]/[listSearch].vue`

```vue
<script setup lang="ts">
import { parseUrl } from '~/seo/seo-listurl-codec'
import { buildListCanonical, buildDefaultMeta, getIndexationMetaTagForList } from '~/utils/html-head.utils'
import { buildListSeoTitle } from '~/seo/seo-title'
import { buildListSeoDescription } from '~/seo/seo-description'
import { setSearchObjectUrl } from '~/utils/search.utils'
import { buildAdKeyValuesFromSearch } from '~/utils/google-ad-manager.utils'
import { 
  fetchExactLocation,
  fetchNettingLinksForList,
  fetchProgramsSummaryForLocation,
  searchAccommodationsForList,
  searchProgramsForList
} from '~/api-resources/api-resources-search-api'
import { getSearchParams } from '~/api-resources/utils'
import { LOCATION_TYPE } from '~/constants/constantes'
import { locWithoutDeptCode } from '~/utils/localisation.utils'
import { LOGGER } from '~/utils/logging.utils'
import { getDataFetchingErrorMessage } from '~/utils/errors.utils'

// Définir le layout
definePageMeta({
  layout: 'list-skeleton',
  validate: async (route) => {
    // Validation des paramètres de route
    return ['programme', 'logement'].includes(route.params.classifiedType as string)
  }
})

const route = useRoute()
const router = useRouter()

// ============================================================================
// DATA FETCHING (remplace getServerSideProps)
// ============================================================================

// Parse l'URL pour obtenir l'objet search
const search = computed(() => setSearchObjectUrl(
  parseUrl(route.fullPath, route.query),
  route.fullPath
))

// Vérifier que la recherche a une location
if (!search.value?.location) {
  throw createError({ statusCode: 404, statusMessage: 'Page Not Found' })
}

// Mapper les paramètres pour exactLoc
const mapExactLocParams = (loc: any) => {
  if (loc.type === LOCATION_TYPE.QUARTIER) {
    const labels = loc.value.split(':')
    return {
      label: labels[0],
      district: labels[1],
      deptCode: loc.departmentCode,
      type: LOCATION_TYPE.properties[loc.type].exactLocType
    }
  }
  
  return {
    label: locWithoutDeptCode(loc),
    deptCode: loc.departmentCode || null,
    type: LOCATION_TYPE.properties[loc.type].exactLocType
  }
}

// Fetch exactLoc
const fetchAllExactLoc = async (locations: any[] = []) => {
  return Promise.all(
    locations.map(async (loc) => {
      const { label, deptCode, type, district } = loc
      const response = await fetchExactLocation(label, deptCode, type, district)
      const locMapKey = label + '_' + (deptCode || '') + (district ? '_' + district : '')
      return response.data?.[locMapKey] || {}
    })
  )
}

// Fetch list items
const isSearchForAccommodations = (searchObj: any) => {
  // Logique pour déterminer si c'est une recherche de logements
  return searchObj.estateType?.includes('accommodation')
}

const fetchListItems = async (searchObj: any) => {
  const searchFunction = isSearchForAccommodations(searchObj) 
    ? searchAccommodationsForList 
    : searchProgramsForList
  return searchFunction(getSearchParams(searchObj))
}

// Fetch programs summary si nécessaire
const fetchProgramsSummaryIfWanted = async (searchObj: any) => {
  if (
    searchObj.location.length === 1 &&
    searchObj.location[0].type > LOCATION_TYPE.PAYS &&
    searchObj.estateType === 'programme'
  ) {
    return fetchProgramsSummaryForLocation(
      searchObj.location[0].value,
      searchObj.location[0].type
    )
  }
  return null
}

// Format exactLoc
const formatExactLoc = (exactLocArray: any[]) => {
  return exactLocArray.filter(Boolean)
}

// Data fetching principal
const exactLocParams = search.value.location.map(mapExactLocParams)

const { data: exactLocData, error: exactLocError } = await useAsyncData(
  'exact-loc',
  () => fetchAllExactLoc(exactLocParams)
)

const { data: listData, error: listError } = await useAsyncData(
  'list-data',
  () => fetchListItems(search.value)
)

// Gestion des erreurs critiques
if (exactLocError.value || listError.value) {
  const errorMsg = getDataFetchingErrorMessage(exactLocError.value || listError.value)
  throw createError({
    statusCode: 500,
    statusMessage: `Error while fetching required data: ${errorMsg}`
  })
}

const exactLoc = computed(() => formatExactLoc(exactLocData.value || []))

// Data fetching optionnel (non-bloquant)
const { data: nettingLinks } = await useAsyncData(
  'netting-links',
  () => fetchNettingLinksForList(search.value, exactLoc.value),
  {
    default: () => ({}),
    server: true,
    lazy: false
  }
)

const { data: programsSummaryData } = await useAsyncData(
  'programs-summary',
  () => fetchProgramsSummaryIfWanted(search.value),
  {
    default: () => null,
    server: true,
    lazy: false
  }
)

// ============================================================================
// COMPUTED VALUES
// ============================================================================

const canonicalUrl = computed(() => buildListCanonical(search.value))
const adKvs = computed(() => buildAdKeyValuesFromSearch(search.value, exactLoc.value))
const isFromEmail = computed(() => route.query['utm_source'] === 'email')

const metaTitle = computed(() => 
  buildListSeoTitle(search.value, exactLoc.value, listData.value?.exactResultsCounter)
)

const metaDescription = computed(() => 
  buildListSeoDescription(
    search.value, 
    exactLoc.value, 
    listData.value?.exactResultsCounter,
    listData.value?.['price-min']
  )
)

const noIndexTags = computed(() => 
  getIndexationMetaTagForList(search.value, listData.value)
)

// ============================================================================
// SEO / HEAD
// ============================================================================

useHead({
  title: metaTitle,
  meta: [
    { name: 'description', content: metaDescription },
    { property: 'og:title', content: metaTitle },
    { property: 'og:description', content: metaDescription },
    { property: 'twitter:title', content: metaTitle },
    { property: 'twitter:description', content: metaDescription },
    ...(noIndexTags.value ? [noIndexTags.value] : [])
  ],
  link: [
    ...(canonicalUrl.value && !noIndexTags.value 
      ? [{ rel: 'canonical', href: canonicalUrl.value }]
      : []
    )
  ]
})

// ============================================================================
// COMPOSABLES
// ============================================================================

// Context pour les alertes
const { alertCreated, setAlertCreated } = useAlertContext()
const alertContextValue = computed(() => ({
  alertCreated: alertCreated.value,
  setAlertCreated,
  search: {}
}))

// Google One Tap
useGoogleOneTap({
  alertCampaign: 'LIST',
  alertOrigin: 'ONE_TAP',
  search: computed(() => mergeExactLocInSearch(search.value, exactLoc.value)),
  disabled: !search.value?.location?.length
})

// Tracking
useListTracking(listData)

// Cookie pour A/B test
onMounted(() => {
  document.cookie = 'FI9_FROM_LIST=true; Path=/; Max-Age=3600'
})

// ============================================================================
// PROVIDE CONTEXT
// ============================================================================

// Fournir le contexte aux composants enfants
provide('alertContext', alertContextValue)
provide('search', search)
provide('exactLoc', exactLoc)
</script>

<template>
  <div>
    <!-- Google Ad Loader -->
    <GoogleAdLoader :page-ads="PAGE_ADS.list" :key-values="adKvs" />
    
    <!-- Google Map Script -->
    <GoogleMapScript />
    
    <!-- Google One Tap Script -->
    <GoogleOneTapScript />
    
    <!-- Le layout list-skeleton gère le reste -->
    <NuxtLayout
      name="list-skeleton"
      :list-data="listData"
      :netting-links="nettingLinks"
      :is-from-email="isFromEmail"
      :programs-summary-data="programsSummaryData"
      :meta-description="metaDescription"
    />
  </div>
</template>
```

---

## Migration des composables

### 1. `composables/useListTracking.ts`

```typescript
import type { Ref } from 'vue'
import { watch } from 'vue'
import { GA_EVENTS, hitTags } from '~/utils/analytics/tracking-tags.utils'

export function useListTracking(listData: Ref<any>) {
  watch(listData, (data) => {
    if (!data) return
    
    // Pole position
    if (data.programs?.filter((program: any) => program.isPolePosition).length > 0) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_pole_po',
        gaCreative: 'pole_position'
      })
    }
    
    // Top classified
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
    
    // Much leads
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
    
    // Few lead
    const programFewLead = data.programs?.find((program: any) => program.isFewLead)
    if (programFewLead) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_annonce_1_3_rdt',
        gaCreative: '1_3_rdt'
      })
    }
    
    // Top clients
    if (data.programs?.some?.((prog: any) => prog.isTopClients)) {
      hitTags(GA_EVENTS.affichage_annonce_mise_en_valeur, {
        label: 'liste_top_client',
        gaCreative: 'top_client'
      })
    }
    
    // Expanded criteria
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

### 2. `composables/useMapDisplay.ts`

```typescript
import type { Ref } from 'vue'
import { ref, watch, onMounted } from 'vue'

const DISPLAY_MAP_STORAGE_KEY = 'FI9_MAP_DISPLAYED'

export function useMapDisplay(layout: Ref<string>) {
  const isMapDisplayed = ref(false)
  
  // Initialisation depuis localStorage
  onMounted(() => {
    if (process.client && layout.value === 'DESKTOP') {
      const stored = localStorage.getItem(DISPLAY_MAP_STORAGE_KEY)
      isMapDisplayed.value = stored === 'true'
    }
  })
  
  // Watch layout changes
  watch(layout, (newLayout) => {
    if (process.client && newLayout === 'DESKTOP') {
      const stored = localStorage.getItem(DISPLAY_MAP_STORAGE_KEY)
      isMapDisplayed.value = stored === 'true'
    }
  })
  
  const handleMapDisplayChange = (newValue: boolean) => {
    isMapDisplayed.value = newValue
    if (process.client) {
      localStorage.setItem(DISPLAY_MAP_STORAGE_KEY, String(newValue))
    }
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

### 3. `composables/useMapPosition.ts`

```typescript
import type { Ref } from 'vue'
import { ref, watch, onMounted, onUnmounted } from 'vue'
import { useDebounceFn } from '@vueuse/core'

export function useMapPosition(
  isMapDisplayed: Ref<boolean>,
  layout: Ref<string>,
  searchBarRef?: Ref<HTMLElement | null>
) {
  const mapPosition = ref<{ top: number; height: number } | null>(null)
  
  const refreshMapPosition = useDebounceFn(() => {
    if (!isMapDisplayed.value) {
      mapPosition.value = null
      return
    }
    
    if (searchBarRef?.value && layout.value === 'DESKTOP') {
      const { bottom: searchBarBottom } = searchBarRef.value.getBoundingClientRect()
      mapPosition.value = {
        top: searchBarBottom,
        height: window.innerHeight - searchBarBottom
      }
    } else {
      mapPosition.value = null
    }
  }, 150)
  
  watch([isMapDisplayed, layout], () => {
    refreshMapPosition()
  })
  
  onMounted(() => {
    if (process.client) {
      window.addEventListener('scroll', refreshMapPosition)
      window.addEventListener('resize', refreshMapPosition)
      refreshMapPosition()
    }
  })
  
  onUnmounted(() => {
    if (process.client) {
      window.removeEventListener('scroll', refreshMapPosition)
      window.removeEventListener('resize', refreshMapPosition)
    }
  })
  
  return {
    mapPosition: readonly(mapPosition)
  }
}
```

### 4. `composables/useListHover.ts`

```typescript
import { ref } from 'vue'

export function useListHover() {
  const hoveredItemId = ref<string | undefined>(undefined)
  
  const handleMouseEnterItem = (id: string) => {
    hoveredItemId.value = id
  }
  
  const handleMouseLeaveItem = () => {
    hoveredItemId.value = undefined
  }
  
  return {
    hoveredItemId: readonly(hoveredItemId),
    handleMouseEnterItem,
    handleMouseLeaveItem
  }
}
```

### 5. `composables/useAlertContext.ts`

```typescript
import { ref } from 'vue'

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
```

### 6. `composables/useListPagination.ts`

```typescript
import type { Ref } from 'vue'
import { ref, watch, onMounted } from 'vue'
import { LOCATION_TYPE } from '~/constants/constantes'

export function useListPagination(
  search: Ref<any>,
  totalCount: Ref<number>,
  baseCount: Ref<number>
) {
  const hidePagination = ref(
    !search.value?.location?.length ||
    [LOCATION_TYPE.PAYS, LOCATION_TYPE.REGION, LOCATION_TYPE.DEPARTEMENT]
      .includes(search.value.location[0]?.type) ||
    totalCount.value > baseCount.value
  )
  
  onMounted(() => {
    // Afficher la pagination côté client
    hidePagination.value = false
  })
  
  return {
    hidePagination: readonly(hidePagination)
  }
}
```

---

## Migration du layout list-skeleton

### Fichier : `layouts/list-skeleton.vue`

```vue
<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { buildListSeoH1 } from '~/seo/seo-h1'
import { buildListPageBreadcrumbs } from '~/utils/breadcrumbs.utils'
import { mergeExactLocInSearch } from '~/utils/search.utils'
import { encodeUrl, toUrl } from '~/seo/seo-listurl-codec'
import { PAGE, LAYOUTS } from '~/constants/constantes'
import { ALERT_CAMPAIGN, ALERT_ORIGIN } from '~/utils/alert.utils'

interface Props {
  listData?: any
  nettingLinks?: any
  isFromEmail?: boolean
  programsSummaryData?: any
  metaDescription?: string
}

const props = defineProps<Props>()

const route = useRoute()
const router = useRouter()

// Inject context from page
const search = inject<Ref<any>>('search')!
const exactLoc = inject<Ref<any>>('exactLoc')!

// Composables
const layout = useScreenLayout()
const { isMapDisplayed, handleMapDisplayChange, openMap } = useMapDisplay(layout)
const { hoveredItemId, handleMouseEnterItem, handleMouseLeaveItem } = useListHover()

// Refs
const searchBarRef = ref<HTMLElement | null>(null)
const programsContainerRef = ref<HTMLElement | null>(null)

// Map position
const { mapPosition } = useMapPosition(isMapDisplayed, layout, searchBarRef)

// Pagination
const totalCount = computed(() => props.listData?.counter || 0)
const baseCount = computed(() => props.listData?.exactResultsCounter || 0)
const { hidePagination } = useListPagination(search, totalCount, baseCount)

// Navigation context
const { backToScrollPosition, scrollPosition, setBackToScrollPosition } = useNavigationContext()
useSaveScrollPosition()

onMounted(() => {
  if (backToScrollPosition.value) {
    window.scrollTo(window.scrollX, scrollPosition.value)
    setBackToScrollPosition(false)
  }
})

// Computed values
const currentPage = computed(() => search.value?.currentPage || 1)
const sortType = computed(() => search.value?.sort)
const totalPageCount = computed(() => props.listData?.pagination?.totalPage)

const isAccommodationList = computed(() => 
  props.listData?.accommodations?.length > 0
)

const listItems = computed(() => 
  isAccommodationList.value 
    ? props.listData.accommodations 
    : props.listData?.programs
)

const enrichedNettingLinks = computed(() => ({
  ...props.nettingLinks,
  seoStaticLinks: props.listData?.['seo-links']?.links
}))

const h1Text = computed(() => buildListSeoH1(search.value, exactLoc.value))

const breadcrumbsData = computed(() => 
  buildListPageBreadcrumbs(mergeExactLocInSearch(search.value, exactLoc.value))
)

// Min/Max prices
const minPrice = computed(() => {
  let minPrices
  if (props.listData?.accommodations?.length) {
    minPrices = props.listData.accommodations
      .filter((item: any) => item.price > 0 || item.priceMin > 0)
      .map((item: any) => item.price || item.priceMin)
  } else {
    minPrices = props.listData?.programs
      ?.filter?.((item: any) => item.priceMin > 0)
      ?.map?.((item: any) => item.priceMin)
  }
  if (!minPrices?.length) return null
  return Math.min(...minPrices)
})

const maxPrice = computed(() => {
  let maxPrices
  if (props.listData?.accommodations?.length) {
    maxPrices = props.listData.accommodations
      .filter((item: any) => item.price > 0 || item.priceMax > 0)
      .map((item: any) => item.price || item.priceMax)
  } else {
    maxPrices = props.listData?.programs
      ?.filter?.((item: any) => item.priceMax > 0)
      ?.map?.((item: any) => item.priceMax)
  }
  if (!maxPrices?.length) return null
  return Math.max(...maxPrices)
})

// Program list for map
const programListForMap = computed(() => {
  if (props.listData?.accommodations?.length > 0) {
    const result: any[] = []
    props.listData.accommodations.forEach((acc: any) => {
      const newProgram = {
        ...acc.program,
        location: acc.location,
        address: acc.location?.city,
        photos: [{ medium: acc.pictureURL }],
        threeDimensionsOnProgram: acc.isVirtualTour3DAvailable,
        videoFr: acc.hasVideo
      }
      if (!result.find(prog => prog.id === newProgram.id)) {
        result.push(newProgram)
      }
    })
    return result
  }
  return props.listData?.programs
})

// Handlers
const refreshSort = (event: Event) => {
  const target = event.target as HTMLSelectElement
  const nextUrl = toUrl({
    ...search.value,
    currentPage: 1,
    sort: target.value
  })
  router.replace(encodeUrl(nextUrl.path, nextUrl.query))
}

const generatePaginationURL = (pageID: number) => {
  const urlObject = toUrl({ ...search.value, currentPage: pageID })
  return encodeUrl(urlObject.path, urlObject.query)
}
</script>

<template>
  <div>
    <SearchBar ref="searchBarRef" />
    
    <div :class="['wrapper', { 'map-open': isMapDisplayed }]" data-e2e="liste-page">
      <div :class="['page-container', { 'map-open': isMapDisplayed }]">
        <div class="main-container">
          <div :class="{ 'no-results': totalCount === 0 }">
            <!-- Schema.org Product -->
            <div v-if="minPrice" itemscope itemtype="https://schema.org/Product">
              <meta itemprop="name" :content="h1Text" />
              <meta itemprop="description" :content="metaDescription" />
              <div itemprop="offers" itemscope itemtype="https://schema.org/AggregateOffer">
                <meta itemprop="url" :content="'https://www.explorimmoneuf.com' + search.url" />
                <meta itemprop="priceCurrency" content="EUR" />
                <meta itemprop="lowPrice" :content="String(minPrice)" />
                <meta v-if="maxPrice" itemprop="highPrice" :content="String(maxPrice)" />
                <meta itemprop="offerCount" :content="String(totalCount)" />
              </div>
            </div>
            
            <div :class="['list-container', { 'map-open': isMapDisplayed }]">
              <div>
                <Breadcrumbs :page="PAGE.LISTE" :breadcrumbs-data="breadcrumbsData" />
                <ListTitle :main-text="h1Text" :result-count="totalCount" />
                
                <template v-if="totalCount !== 0">
                  <SeoTopContent :content="listData?.['seo-content']?.textTop" />
                  
                  <GoogleAdContainer
                    :ad-code="AD_CODE.listeHautMbanAtf"
                    :class="['ad-banner', 'hide-on-desktop']"
                  />
                  
                  <IndicatorsSection :indicators="listData?.pressureIndicators" />
                  
                  <Sortbar
                    v-if="baseCount > 0"
                    :sort-type="sortType"
                    :is-map-displayed="isMapDisplayed"
                    @change-select="refreshSort"
                    @map-display-change="handleMapDisplayChange"
                  />
                </template>
                
                <div ref="programsContainerRef" data-e2e="bloc-annonces">
                  <ListAnnonces
                    v-if="totalCount > 0"
                    :list-items="listItems"
                    :page="PAGE.LISTE"
                    :search="search"
                    :display-expanded-search-separators="currentPage === 1 && totalCount > baseCount"
                    :is-accommodation-list="isAccommodationList"
                    @mouse-enter-item="handleMouseEnterItem"
                    @mouse-leave-item="handleMouseLeaveItem"
                  />
                  
                  <AlertButton
                    v-if="search.location?.length"
                    tc-label="liste_toolbar"
                    id-object="option-end-list"
                    :campaign="ALERT_CAMPAIGN.LIST"
                    :origin="ALERT_ORIGIN.MANUAL"
                  />
                  
                  <PaginationMenu
                    v-if="!hidePagination && totalCount !== 0"
                    :current-page="currentPage"
                    :total-page-count="totalPageCount"
                    :page-url-generator="generatePaginationURL"
                  />
                  
                  <template v-if="totalCount === 0">
                    <p class="no-result-text">
                      Aucune annonce répondant à vos critères n'a été trouvée pour le moment.
                    </p>
                    
                    <div v-if="search.location?.length" class="no-result-alert">
                      <AlertForm
                        id-option="option-list"
                        conf-alert-tc-label="liste_0_resultat"
                        :campaign="ALERT_CAMPAIGN.LIST"
                        :origin="ALERT_ORIGIN.MANUAL"
                      />
                    </div>
                  </template>
                </div>
              </div>
              
              <SidebarList
                :is-map-displayed="isMapDisplayed"
                :on-open-map="baseCount && openMap"
                :program-count="programListForMap?.length"
              />
            </div>
          </div>
          
          <DonePrograms
            v-if="!search?.estateType?.length"
            :items="listData?.lastUnavailablePrograms"
            :locations="exactLoc"
            :is-display-column="isMapDisplayed"
            class="section"
          />
          
          <TopPromoters
            v-if="!search?.estateType?.length"
            :promoters="listData?.topPromoters"
            :locations="exactLoc"
            :is-display-column="isMapDisplayed"
            class="section"
          />
          
          <SeoNettingLinks
            :links="enrichedNettingLinks"
            :search="search"
            :exact-loc="exactLoc"
            class="section"
          />
          
          <div
            v-if="listData?.['seo-content']?.textBottom"
            class="section bottom-seo-text"
            v-html="listData['seo-content'].textBottom"
          />
          
          <div
            v-if="programsSummaryData?.programCount || listData?.seoDescription?.length"
            class="section"
            itemscope
            itemtype="https://schema.org/FAQPage"
          >
            <h2>FAQ - Questions Fréquentes</h2>
            
            <SeoTextGaps
              v-if="programsSummaryData"
              :location="exactLoc[0]"
              :programs-summary-data="programsSummaryData"
              :is-map-displayed="isMapDisplayed"
            />
            
            <SeoDescription
              :location="exactLoc[0]"
              :seo-description="listData?.seoDescription"
              :programs-summary-data="programsSummaryData"
              :expand-first-question="!programsSummaryData?.programCount"
              :is-map-displayed="isMapDisplayed"
            />
          </div>
          
          <AdSense />
        </div>
        
        <AlertToaster
          v-if="search.location?.length && !isFromEmail && currentPage === 1"
          :locations="search?.location"
          :programs-container-ref="programsContainerRef"
          must-be-opened-with-scroll
        />
        
        <Footer :is-half-screen="isMapDisplayed" class="footer" />
      </div>
      
      <div :class="['map-container', { 'map-open': isMapDisplayed }]">
        <ContainerMapSearch
          :map-is-displayed="isMapDisplayed"
          :hovered-item-id="hoveredItemId"
          :map-position="mapPosition"
          :programs="programListForMap"
          @map-display-change="handleMapDisplayChange"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
@layer layout {
  .wrapper {
    display: flex;
    position: relative;
    
    &.map-open {
      .page-container {
        width: 50%;
      }
      
      .map-container {
        width: 50%;
        display: block;
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
  
  .list-container {
    display: grid;
    grid-template-columns: 1fr;
    gap: 20px;
    
    &.map-open {
      grid-template-columns: 1fr 300px;
    }
    
    @media (max-width: 1024px) {
      grid-template-columns: 1fr !important;
    }
  }
  
  .map-container {
    display: none;
    position: fixed;
    right: 0;
    top: 0;
    height: 100vh;
    
    &.map-open {
      display: block;
    }
  }
  
  .section {
    margin-top: 40px;
    padding: 20px;
    background: white;
    border-radius: 8px;
  }
  
  .bottom-seo-text {
    :deep(h2) {
      font-size: 24px;
      margin-bottom: 16px;
    }
    
    :deep(p) {
      line-height: 1.6;
      color: #333;
    }
  }
  
  .no-result-text {
    text-align: center;
    font-size: 18px;
    color: #666;
    padding: 40px 20px;
  }
  
  .no-result-alert {
    max-width: 600px;
    margin: 0 auto;
    padding: 20px;
  }
  
  .ad-banner {
    margin: 20px 0;
    
    &.hide-on-desktop {
      @media (min-width: 1024px) {
        display: none;
      }
    }
  }
  
  .footer {
    margin-top: 60px;
  }
}
</style>
```

---

## Migration des composants

### Exemple : `components/list/Sortbar.vue`

```vue
<script setup lang="ts">
interface Props {
  sortType?: string
  isMapDisplayed: boolean
}

interface Emits {
  (e: 'changeSelect', event: Event): void
  (e: 'mapDisplayChange', value: boolean): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const handleSortChange = (event: Event) => {
  emit('changeSelect', event)
}

const toggleMap = () => {
  emit('mapDisplayChange', !props.isMapDisplayed)
}
</script>

<template>
  <div class="sortbar">
    <div class="sort-controls">
      <label for="sort-select" class="sort-label">Trier par :</label>
      <select 
        id="sort-select"
        :value="sortType"
        class="sort-select"
        @change="handleSortChange"
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
      type="button"
      @click="toggleMap"
    >
      <span class="icon" aria-hidden="true">📍</span>
      <span>{{ isMapDisplayed ? 'Masquer' : 'Afficher' }} la carte</span>
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
    margin-bottom: 1.5rem;
    
    @media (max-width: 768px) {
      flex-direction: column;
      gap: 1rem;
      align-items: stretch;
    }
  }
  
  .sort-controls {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }
  
  .sort-label {
    font-weight: 500;
    color: #333;
    white-space: nowrap;
  }
  
  .sort-select {
    padding: 0.5rem 2rem 0.5rem 1rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    background: white;
    cursor: pointer;
    font-size: 14px;
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23333' d='M6 9L1 4h10z'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 0.75rem center;
    
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
    font-size: 14px;
    font-weight: 500;
    
    &:hover {
      background: #f8f9fa;
      border-color: #007bff;
    }
    
    &:focus {
      outline: none;
      box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
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
    line-height: 1;
  }
}
</style>
```

---

## Scripts de migration

### Script bash pour créer la structure

```bash
#!/bin/bash

# Script de création de la structure pour la migration
# Usage: ./create-structure.sh

BASE_DIR="fi9-front-nuxt/app"

# Créer les dossiers
mkdir -p "$BASE_DIR/pages/[classifiedType]"
mkdir -p "$BASE_DIR/layouts"
mkdir -p "$BASE_DIR/components/list"
mkdir -p "$BASE_DIR/composables"

# Créer les fichiers composables
touch "$BASE_DIR/composables/useListTracking.ts"
touch "$BASE_DIR/composables/useMapDisplay.ts"
touch "$BASE_DIR/composables/useMapPosition.ts"
touch "$BASE_DIR/composables/useListHover.ts"
touch "$BASE_DIR/composables/useAlertContext.ts"
touch "$BASE_DIR/composables/useListPagination.ts"

# Créer le layout
touch "$BASE_DIR/layouts/list-skeleton.vue"

# Créer la page
touch "$BASE_DIR/pages/[classifiedType]/[listSearch].vue"

# Créer les composants
touch "$BASE_DIR/components/list/ListTitle.vue"
touch "$BASE_DIR/components/list/Sortbar.vue"
touch "$BASE_DIR/components/list/SidebarList.vue"
touch "$BASE_DIR/components/list/ListAnnonces.vue"
touch "$BASE_DIR/components/list/IndicatorsSection.vue"
touch "$BASE_DIR/components/list/SeoDescription.vue"
touch "$BASE_DIR/components/list/SeoTextGaps.vue"
touch "$BASE_DIR/components/list/DonePrograms.vue"
touch "$BASE_DIR/components/list/TopPromoters.vue"

echo "✅ Structure créée avec succès!"
```

### Script Node.js pour transformer les CSS modules

```javascript
// transform-css-modules.js
const fs = require('fs');
const path = require('path');

function transformCssModule(content) {
  // Transformer les sélecteurs en nesting
  let transformed = content;
  
  // Ajouter @layer components
  transformed = `@layer components {\n${transformed}\n}`;
  
  // Transformer les sélecteurs imbriqués basiques
  // Exemple: .parent .child {} -> .parent { .child {} }
  // Cette transformation est simplifiée, un vrai parser CSS serait mieux
  
  return transformed;
}

function processFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const transformed = transformCssModule(content);
  
  // Créer le nouveau fichier dans le projet Nuxt
  const newPath = filePath
    .replace('fi9-front/', 'fi9-front-nuxt/app/')
    .replace('.module.scss', '.scoped.css');
  
  const dir = path.dirname(newPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(newPath, transformed);
  console.log(`✅ Transformé: ${filePath} -> ${newPath}`);
}

// Utilisation
const moduleCssFiles = [
  'page-fragments/list/ListTitle/list-title.module.scss',
  'page-fragments/list/Sortbar/sortbar.module.scss',
  // ... autres fichiers
];

moduleCssFiles.forEach(file => {
  processFile(path.join('fi9-front', file));
});
```

---

## Ordre d'exécution recommandé

1. **Créer la structure** : Exécuter `create-structure.sh`
2. **Migrer les composables** : Copier le code des composables
3. **Migrer les composants simples** : Commencer par ListTitle, Sortbar
4. **Migrer les composants complexes** : IndicatorsSection, etc.
5. **Migrer le layout** : list-skeleton.vue
6. **Migrer la page** : [listSearch].vue
7. **Tester** : Vérifier le rendu et le fonctionnement

---

## Checklist de validation

- [ ] La page se charge correctement en SSR
- [ ] Les meta tags SEO sont présents
- [ ] Le tracking analytics fonctionne
- [ ] La carte s'affiche/se masque correctement
- [ ] Le tri fonctionne
- [ ] La pagination fonctionne
- [ ] Les styles sont identiques à la version Next.js
- [ ] Pas d'erreurs d'hydratation
- [ ] Les performances sont bonnes (Lighthouse)
