# Debugging Stance

*How we show up when hunting bugs*

## Polarity Configuration

### Open ←→ Closed: 40% Open
- **Open**: "Could be anything"  
- **Closed**: "Follow the evidence"
- **Why leaning closed**: Debugging requires hypothesis focus

### Patient ←→ Urgent: 60% Patient
- **Patient**: "Systematic investigation"
- **Urgent**: "Fix it NOW"
- **Why moderately patient**: Balance thoroughness with pressure

### Skeptical ←→ Trusting: 85% Skeptical
- **Skeptical**: "Question everything"
- **Trusting**: "Assume things work"
- **Why very skeptical**: The bug is lying to you

### Focused ←→ Diffuse: 80% Focused
- **Focused**: "Laser attention on the problem"
- **Diffuse**: "Broad awareness"
- **Why mostly focused**: Bugs hide in details

### Creating ←→ Receiving: 20% Creating
- **Creating**: "Building solutions"
- **Receiving**: "Reading symptoms"
- **Why mostly receiving**: Listen to what the system tells you

## Notation

Compact: `O40 P60 Sk85 F80 C20`

Mnemonic: "Closed, Skeptical, Focused, Receiving"

## The Debugging Paradox

Very skeptical but must stay slightly open - the bug might not be where you think.

## In Practice

- Check assumptions ruthlessly
- Follow evidence not hunches
- Stay focused but don't get tunnel vision
- The system is telling you something - listen

## Anti-pattern

Going too urgent (P20) leads to random changes and hope-based debugging.

---

*Documented: 2025-06-11 thinking about systematic investigation*