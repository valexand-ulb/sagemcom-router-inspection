# memory dump

## NAND dump
The whole flash nand0 has a size of 128 Mib (0x08000000) so simple guess is to execute 
```
CFE > dm 0x00000000 0x08000000
```
> 📖
> dump whole memory from init address
> ❌
>  Exception like if the memory is not accessible :/

## Viable option ?

1. `0xb0820650` - Mentioned during the FAP (Forwarding Assist Processor) initialization as managed memory.
2. `0xb0a20650` - Another managed memory address for the second FAP instance.
3. `0x80002000` - Used for PSM (Private Segment Memory) with detailed usage statistics.
4. `0xabfb4000 to 0xabfb8000` - Memory range used by SWQ (Software Queue) for FAP0. ❌ Seems unresponsive
5. `0xabfc8000 to 0xabfcc000` - Memory range used by SWQ for FAP1.

### Dump uboot ? 
```
dm 0x8ff00000 0x100000
```
> ⚠️ Size is subjective
> Dump seems repetitive  (one repeated is only `0xFF`)

once in u-boot (not cfe) test with :
```
md 0x8ff00000 0x100000
```
> ✅
> seems responsive, will try with size `0x1f00000` (c.f env_var.md)

```
md 0x8ff00000 0x1f00000
```
> ✅
> Dump nearly successfull (bunch of `dead dead` at the end)
> Has been converted to bin
> Has been analyzed with string analysis.


### Dump loaded firmware image ?
```
dm 0x80400000 0x100000
```
> ⚠️ Size is subjective
> ❌ does not seems to be that (full of `0xFF`) to retry with `md` from u-boot
