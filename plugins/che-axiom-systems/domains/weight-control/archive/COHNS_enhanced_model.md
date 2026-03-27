# COHNS Enhanced Balance Model

## Sodium-Enhanced Weight Prediction Equation

### Core Balance Equation
```
ΔM_body = ΔM_COHN + ΔM_Na-water
```

Where:
```
ΔM_Na-water = ΔNa × 140
```

### Sodium Balance Components

#### Input
- Food sodium
- Salt intake
- Electrolyte drinks

#### Output  
- Urinary sodium (primary)
- Sweat sodium (exercise)
- Fecal sodium (minor)

### Integrated Tracking

```python
class COHNSBalance:
    def __init__(self):
        self.water_per_sodium = 140  # g water per g Na
        
    def calculate_sodium_effect(self, Na_in, Na_out):
        delta_Na = Na_in - Na_out
        water_change = delta_Na * self.water_per_sodium
        return delta_Na, water_change
    
    def predict_daily_weight(self, cohn_change, Na_in, Na_out):
        base_change = cohn_change  # from COHN calculation
        na_effect, water_effect = self.calculate_sodium_effect(Na_in, Na_out)
        
        total_change = base_change + na_effect + water_effect
        
        return {
            'metabolic_change': base_change,
            'sodium_change': na_effect,
            'water_change': water_effect,
            'total_change': total_change
        }
```

## Clinical Applications

### 1. Distinguishing Weight Changes
- **True fat loss**: COHN negative, Na stable
- **Water retention**: COHN stable, Na positive  
- **Dehydration**: H2O negative, Na negative
- **Refeeding**: COHN positive, Na positive

### 2. Optimizing Weight Loss
- Monitor Na to avoid masking fat loss
- Time weigh-ins based on Na cycles
- Adjust sodium for competitions

### 3. Medical Monitoring
- Heart failure (fluid status)
- Kidney disease (Na retention)
- Hypertension (Na sensitivity)

## Practical Implementation

### Daily Measurements
1. **Morning**: Weight, urine Na strip
2. **Meals**: Track sodium content
3. **Evening**: Calculate daily balance
4. **Weekly**: Average to see true trends

### Sodium Cycling Patterns
- **Daily**: ±200-400g from Na-water
- **Menstrual**: ±500-1000g from hormonal Na retention
- **Post-exercise**: -200-500g from sweat Na loss
- **High-carb meal**: +300-500g from glycogen-Na-water

## Conclusion

The COHNS model (COHN + Sodium) represents the optimal balance between:
- **Completeness**: Captures all major weight fluctuations
- **Practicality**: Still measurable with available tools
- **Clinical utility**: Distinguishes metabolic vs water weight

Beyond COHNS, additional elements provide diminishing returns for most applications.

---
*Addendum to COHN Balance Theory*  
*Version: 1.1*