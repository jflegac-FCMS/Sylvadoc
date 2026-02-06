#!/bin/bash

# Script de création de la structure pour la migration Next.js → Nuxt.js
# Usage: ./create-migration-structure.sh

set -e

echo "🚀 Création de la structure de migration Next.js → Nuxt.js"
echo ""

# Définir le répertoire de base
BASE_DIR="/home/sylvadoc/Documents/FI9/fi9-front-nuxt/app"

# Vérifier que le répertoire existe
if [ ! -d "$BASE_DIR" ]; then
    echo "❌ Erreur: Le répertoire $BASE_DIR n'existe pas"
    exit 1
fi

echo "📁 Création des dossiers..."

# Créer la structure de dossiers
mkdir -p "$BASE_DIR/pages/[classifiedType]"
mkdir -p "$BASE_DIR/layouts"
mkdir -p "$BASE_DIR/components/list"
mkdir -p "$BASE_DIR/composables"

echo "✅ Dossiers créés"
echo ""

echo "📝 Création des fichiers composables..."

# Créer les fichiers composables avec des templates de base
cat > "$BASE_DIR/composables/useListTracking.ts" << 'EOF'
import type { Ref } from 'vue'
import { watch } from 'vue'

/**
 * Composable pour le tracking analytics de la liste
 * @param listData - Données de la liste
 */
export function useListTracking(listData: Ref<any>) {
  watch(listData, (data) => {
    if (!data) return
    
    // TODO: Implémenter la logique de tracking
    console.log('List tracking:', data)
  }, { immediate: true })
}
EOF

cat > "$BASE_DIR/composables/useMapDisplay.ts" << 'EOF'
import type { Ref } from 'vue'
import { ref, watch, onMounted } from 'vue'

const DISPLAY_MAP_STORAGE_KEY = 'FI9_MAP_DISPLAYED'

/**
 * Composable pour gérer l'affichage de la carte
 * @param layout - Layout actuel (DESKTOP, MOBILE, etc.)
 */
export function useMapDisplay(layout: Ref<string>) {
  const isMapDisplayed = ref(false)
  
  onMounted(() => {
    if (process.client && layout.value === 'DESKTOP') {
      const stored = localStorage.getItem(DISPLAY_MAP_STORAGE_KEY)
      isMapDisplayed.value = stored === 'true'
    }
  })
  
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
EOF

cat > "$BASE_DIR/composables/useMapPosition.ts" << 'EOF'
import type { Ref } from 'vue'
import { ref, watch, onMounted, onUnmounted } from 'vue'

/**
 * Composable pour gérer la position de la carte
 */
export function useMapPosition(
  isMapDisplayed: Ref<boolean>,
  layout: Ref<string>,
  searchBarRef?: Ref<HTMLElement | null>
) {
  const mapPosition = ref<{ top: number; height: number } | null>(null)
  
  // TODO: Implémenter la logique de position
  
  return {
    mapPosition: readonly(mapPosition)
  }
}
EOF

cat > "$BASE_DIR/composables/useListHover.ts" << 'EOF'
import { ref } from 'vue'

/**
 * Composable pour gérer le hover sur les items de la liste
 */
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
EOF

cat > "$BASE_DIR/composables/useAlertContext.ts" << 'EOF'
import { ref } from 'vue'

/**
 * Composable pour gérer le contexte des alertes
 */
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
EOF

cat > "$BASE_DIR/composables/useListPagination.ts" << 'EOF'
import type { Ref } from 'vue'
import { ref, onMounted } from 'vue'

/**
 * Composable pour gérer la pagination de la liste
 */
export function useListPagination(
  search: Ref<any>,
  totalCount: Ref<number>,
  baseCount: Ref<number>
) {
  const hidePagination = ref(true)
  
  onMounted(() => {
    hidePagination.value = false
  })
  
  return {
    hidePagination: readonly(hidePagination)
  }
}
EOF

echo "✅ Composables créés"
echo ""

echo "📝 Création des templates de composants..."

# Créer les templates de composants
cat > "$BASE_DIR/components/list/ListTitle.vue" << 'EOF'
<script setup lang="ts">
interface Props {
  mainText: string
  resultCount: number
}

defineProps<Props>()
</script>

<template>
  <div class="list-title">
    <h1 class="title">{{ mainText }}</h1>
    <span class="count">{{ resultCount }} résultats</span>
  </div>
</template>

<style scoped>
@layer components {
  .list-title {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 0;
  }
  
  .title {
    font-size: 1.5rem;
    font-weight: bold;
    margin: 0;
  }
  
  .count {
    color: #666;
    font-size: 0.9rem;
  }
}
</style>
EOF

cat > "$BASE_DIR/components/list/Sortbar.vue" << 'EOF'
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
</script>

<template>
  <div class="sortbar">
    <!-- TODO: Implémenter le contenu -->
  </div>
</template>

<style scoped>
@layer components {
  .sortbar {
    /* TODO: Ajouter les styles */
  }
}
</style>
EOF

echo "✅ Templates de composants créés"
echo ""

echo "📝 Création du template de layout..."

cat > "$BASE_DIR/layouts/list-skeleton.vue" << 'EOF'
<script setup lang="ts">
interface Props {
  listData?: any
  nettingLinks?: any
  isFromEmail?: boolean
  programsSummaryData?: any
  metaDescription?: string
}

const props = defineProps<Props>()

// TODO: Implémenter la logique du layout
</script>

<template>
  <div class="list-skeleton">
    <slot />
    <!-- TODO: Implémenter le template -->
  </div>
</template>

<style scoped>
@layer layout {
  .list-skeleton {
    /* TODO: Ajouter les styles */
  }
}
</style>
EOF

echo "✅ Template de layout créé"
echo ""

echo "📝 Création du template de page..."

cat > "$BASE_DIR/pages/[classifiedType]/[listSearch].vue" << 'EOF'
<script setup lang="ts">
definePageMeta({
  layout: 'list-skeleton',
  validate: async (route) => {
    return ['programme', 'logement'].includes(route.params.classifiedType as string)
  }
})

const route = useRoute()

// TODO: Implémenter la logique de data fetching
</script>

<template>
  <div>
    <!-- TODO: Implémenter le template -->
  </div>
</template>
EOF

echo "✅ Template de page créé"
echo ""

echo "📊 Résumé de la structure créée:"
echo ""
echo "📁 $BASE_DIR/"
echo "   ├── pages/"
echo "   │   └── [classifiedType]/"
echo "   │       └── [listSearch].vue"
echo "   ├── layouts/"
echo "   │   └── list-skeleton.vue"
echo "   ├── components/"
echo "   │   └── list/"
echo "   │       ├── ListTitle.vue"
echo "   │       └── Sortbar.vue"
echo "   └── composables/"
echo "       ├── useListTracking.ts"
echo "       ├── useMapDisplay.ts"
echo "       ├── useMapPosition.ts"
echo "       ├── useListHover.ts"
echo "       ├── useAlertContext.ts"
echo "       └── useListPagination.ts"
echo ""
echo "✅ Structure de migration créée avec succès!"
echo ""
echo "📚 Prochaines étapes:"
echo "   1. Consulter la documentation dans les fichiers .md"
echo "   2. Implémenter la logique dans les composables"
echo "   3. Migrer les composants un par un"
echo "   4. Implémenter le layout list-skeleton.vue"
echo "   5. Implémenter la page [listSearch].vue"
echo "   6. Tester avec: cd $BASE_DIR/../.. && npm run dev"
echo ""
