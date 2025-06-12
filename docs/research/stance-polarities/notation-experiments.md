# Notation Experiments

*Different ways to express stance configurations*

## 1. Percentage Notation
```
O70 P85 C65 Pr90 Cr30
```
- Pro: Precise, compact
- Con: Need legend, hard to scan

## 2. Visual Bar
```
Open    ●●●●●●●○○○
Patient ●●●●●●●●●○
Critical ●●●●●●○○○○
```
- Pro: Instantly visual
- Con: Takes space, hard to type

## 3. Emoji Scale
```
Open: 🟢🟢🟢🟢⚪
Patient: 🟢🟢🟢🟢🟢
Critical: 🟢🟢🟢⚪⚪
```
- Pro: Visual, fun
- Con: Not precise enough

## 4. Natural Language
```
Very open, extremely patient, moderately critical
```
- Pro: Readable
- Con: Subjective, verbose

## 5. Plus/Minus
```
Open+++ Patient++++ Critical++ Present++++ Creating-
```
- Pro: Shows direction clearly
- Con: Low resolution

## 6. Musical Notation
```
O♯♯ P♯♯♯♯ C♯ Pr♯♯♯♯ Cr♭
```
- Pro: Compact, shows "sharp" or "flat"
- Con: Requires musical knowledge

## 7. Stance Formula
```
revision = open(70) × patient(85) × critical(65) × present(90) × receiving(70)
```
- Pro: Shows it's multiplicative
- Con: Too mathematical

## Current Winner: Context-Dependent

Quick note: `O70 P85 C65`
Visual check: `●●●●●●●○○○`
Conversation: "pretty open, very patient"

## Insight

The notation itself might need stance:
- Debugging wants precision (percentages)
- Exploration wants looseness (natural language)
- Teaching wants visual (bars/emoji)