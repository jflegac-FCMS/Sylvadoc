---
name: css-development
description: Les préférences de Sylvadoc pour la confection des feuilles de style CSS
---

# Préférences pour le développement CSS

Préférences pour confectionner les feuilles de style CSS modernes, maintenables et performantes.

## Principes généraux

| Aspect               | Choix                                                                 |
|----------------------|------------------------------------------------------------------------|
| Syntaxe CSS          | CSS standard avec fonctionnalités modernes (nids, variables, etc.)          |
| Organisation         | Utilisation de couches CSS (CSS layers) et de nids (CSS nesting)               |
| Variables            | Utilisation de variables CSS personnalisées pour la théme et les styles réutilisables |
| Performance          | Minification et optimisation des feuilles de style lors de la construction          |
| Outils               | PostCSS pour la transformation et l'optimisation des CSS                |
| Méthodologie         | BEM (Block Element Modifier) pour la structuration des classes CSS       |
| Accessibilité        | Respect des normes d'accessibilité (WCAG) dans les styles                |
| Compatibilité        | Utilisation de préfixes automatiques pour la compatibilité entre navigateurs  |
|----------------------|------------------------------------------------------------------------|

## Organisation des styles

| Technique            | Description                                                            |
|----------------------|------------------------------------------------------------------------|
| Couches CSS          | Utilisation de `@layer` pour organiser les styles en couches logiques          |
| Nids CSS             | Utilisation de nids pour une meilleure lisibilité et organisation des sélecteurs       |
| Variables CSS        | Définition de variables CSS pour les couleurs, espacements, typographies, etc.         |
| Fichiers séparés     | Organisation des styles dans des fichiers séparés par fonctionnalité ou composant      |
| Importations         | Utilisation de `@import` pour inclure des fichiers CSS modulaires               |
|----------------------|------------------------------------------------------------------------|

## Outils et automatisation

| Outil                | Usage                                                                  |
|----------------------|------------------------------------------------------------------------|
| PostCSS              | Transformation et optimisation des CSS                                 |
| Autoprefixer         | Ajout automatique de préfixes pour la compatibilité entre navigateurs          |
| CSS Minifier         | Minification des feuilles de style pour la production                          |
| Linting CSS          | Utilisation d'outils de linting pour assurer la qualité des styles                |
| Audits de performance| Utilisation d'outils comme Lighthouse pour auditer la performance des styles       |
|----------------------|------------------------------------------------------------------------|

## Meilleures pratiques

| Pratique             | Description                                                            |
|----------------------|------------------------------------------------------------------------|
| Nommage cohérent     | Utilisation de conventions de nommage cohérentes (BEM) pour les classes CSS               |
| Réutilisabilité      | Création de styles réutilisables et modulaires                                 |
| Accessibilité        | Assurer que les styles respectent les normes d'accessibilité (WCAG)                  |
| Performance          | Optimisation des styles pour minimiser l'impact sur les performances de chargement          |
| Documentation        | Documentation claire des choix de styles et des conventions utilisées                     |
|----------------------|------------------------------------------------------------------------|

## Préférences personnelles

| Préférence  | Description                                                                                                   |
|-------------|---------------------------------------------------------------------------------------------------------------|
| line-height | Utiliser seulement les valeurs numériques (ex: 1.5, 2)                                                        |
| couleurs    | Préférer les variables CSS                                                                                    |
| unités      | Utiliser `rem` ou `ch` pour les tailles, ne jamais utiliser `px`                                              |
| marges      | Utiliser des variables CSS pour les espacements                                                               |
| padding     | Utiliser des variables CSS pour les espacements                                                               |
| nombres magiques | Éviter autant que possible les nombres magiques, utiliser des variables CSS                                   |
| nesting     | Utiliser le nesting CSS pour une meilleure organisation des sélecteurs, mais pas plus de 3 niveaux de nesting |
| responsive | Utiliser d'abord des container queries, et ensuite des media queries si nécessaires                           |
| commentaires | Ajouter des commentaires pour expliquer les sections complexes ou les choix non évidents                      |
|-------------| --------------------------------                                                                              |


## Exemple de structure de fichiers CSS

```
styles/
├── base/
│   ├── _reset.css
│   ├── _typography.css
│   └── _variables.css
├── components/
│   ├── _button.css
│   ├── _card.css
│   └── _modal.css
├── layout/
│   ├── _header.css
│   ├── _footer.css
│   └── _grid.css
├── pages/
│   ├── _home.css
│   └── _about.css
└── main.css
```

## Exemple d'utilisation des variables CSS

```css
:root {
    --color-primary: #3498db;
    --color-secondary: #2ecc71;
    --font-family-base: 'Helvetica Neue', sans-serif;
    --spacing-base: 1rem;
}   
body {
    font-family: var(--font-family-base);
    margin: var(--spacing-base);
    background-color: var(--color-primary);
    color: #fff;
}
```

## Exemple de couche CSS

```css
@layer base {
    body {
        margin: 0;
        padding: 0;
        font-family: var(--font-family-base);
    }
}   

@layer components {
    .button {
        background-color: var(--color-primary);
        color: #fff;
        padding: calc(var(--spacing-base) / 2) var(--spacing-base);
        border: none;
        border-radius: 0.4rem;
        cursor: pointer;
    }
}
```

## Exemple de nid CSS

```css
.card {
    border: 0.1rem solid #ccc;
    border-radius: 0.8rem;
    padding: var(--spacing-base);
    background-color: #fff; 
    .card-header {
        font-weight: bold;
        margin-bottom: calc(var(--spacing-base) / 2);
    }   
    .card-body {
        font-size: 1.4rem;
        color: #333;
    }
}
```
