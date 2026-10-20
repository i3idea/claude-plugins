# Dipendenze tra task

← [Indice della skill](../SKILL.md) · Vedi anche: [ordinamento e stime](ordering-and-estimation.md) · [sprint](sprints.md)

Vincoli FS/SS/FF/SF tra task con auto-schedule.

**Quando serve:** modellare "X non può iniziare finché Y non finisce" (o varianti) per
pianificazione/Gantt, o capire cosa blocca cosa prima di dire a qualcuno "puoi partire".

`list/retrieve/create/update/partial_update/destroy_taskdependencies` (path:
`company_id` + `project_id`). Ogni dipendenza ha un `predecessor`, un `successor`, un
`dependency_type` — **FS** (finish-to-start, default: il successor parte dopo che il
predecessor finisce), **SS** (start-to-start), **FF** (finish-to-finish), **SF**
(start-to-finish) — e `lag_days` (può essere negativo, sposta il vincolo).

Creare/aggiornare una dipendenza **ripropaga automaticamente** le date pianificate del
successor (auto-schedule) se il nuovo vincolo lo richiede. Rifiutata con 400 su
self-link, dipendenza cross-progetto, relazione antenato/discendente, o se crea un
ciclo. Cancellare una dipendenza non riporta indietro le date già spostate.

```
create_taskdependencies(company_id=1, project_id=7, body={
  "predecessor": 1200,
  "successor": 1234,
  "dependency_type": "FS",
  "lag_days": 2
})
```

Per le dipendenze di un **singolo** task passa `task`: matcha da entrambi i versi —
sia le dipendenze che lo bloccano, sia quelle che dipendono da lui. Senza, ricevi
l'intero grafo del progetto.

```
list_taskdependencies(company_id=1, project_id=7, task=1234)
```
