# ------------------------------------------------------------------
# ------------- In-simulation procedures and reporting -------------
# ------------------------------------------------------------------

set added 0
set avg(dcload) 0.0
set avg(samples) 0
set avg(linkC3H_load) 0
set totalConsumptionFile [open "totalConsumptionReport.tr" w]

for {set k 0} {$k < $top(NServers)} {incr k} {
  set avg(servload-$k) 0
  set avg(servloadmem-$k) 0
  set avg(servloadstor-$k) 0
  set avg(queueHC3_pkts-$k) 0
}

for {set k 0} {$k < $virt(NVms)} {incr k} {
   set avg(vmload-$k) 0
   set avg(vmloadmem-$k) 0
   set avg(vmloadstor-$k) 0
}

# Procedure to record graphs
proc record_graphs {} {
  global totalConsumptionFile clouduser_ added energyModel_C1_ energyModel_C2_ energyModel_C3_ sim DCenter graph avg qmon_C3_hosts_ qmon_hosts_C3_ qmon_C3_C2_ top hosts_ mon racks_ vms_ virt
  
  set ns [Simulator instance]
  set now [$ns now]
  set i 1
  set task(genrate) [expr [$DCenter set mips_capacity_]/300000*1]	;# Number of tasks to be generated per second to maintain target Data Center load
  set task(netrate) [expr $task(genrate)*8500*8]					;# Required bitrate
  
  # Data center load
  $DCenter compute-load
  puts $graph(DCload) "$now [$DCenter set avgLoad_]"
  puts $graph(DCloadMem) "$now [$DCenter set avgLoadMem_]"
  puts $graph(DCloadStor) "$now [$DCenter set avgLoadStor_]"
  puts $graph(DCpower) "$now [$DCenter set avgPower_]"
  
  # servers consumption
  set servConsumption 0
  for {set i 0} {$i < [array size hosts_]} {incr i} {
  	set increment [$hosts_($i) set eCurrentConsumption_]
    set servConsumption [expr $servConsumption + $increment]
  }

  # puts "Load: $now [$DCenter set avgLoad_]"
  
  # core switches consumption
  set c1Consumption 0
  for {set i 0} {$i < [array size energyModel_C1_]} {incr i} {
  	set increment [$energyModel_C1_($i) set eCurrentRate_]
    set c1Consumption [expr $c1Consumption + $increment]
  } 
  
  # aggregation switches consumption
  set c2Consumption 0
  for {set i 0} {$i < [array size energyModel_C2_]} {incr i} {
  	set increment [$energyModel_C2_($i) set eCurrentRate_]
    set c2Consumption [expr $c2Consumption + $increment]
  } 
  # puts "$now $c2Consumption"

  # access switches consumption
  set c3Consumption 0
  set c3Consumption 0
  for {set i 0} {$i < [array size energyModel_C3_]} {incr i} {
  	set increment [$energyModel_C3_($i) set eCurrentRate_]
    set c3Consumption [expr $c3Consumption + $increment]
  } 
  
  # total consumption
  set totalConsumption [expr $servConsumption + $c1Consumption + $c2Consumption + $c3Consumption]

  set switchesConsumption [expr $c1Consumption + $c2Consumption + $c3Consumption]


  puts $totalConsumptionFile "$now $totalConsumption"

  set avg(dcload) [expr $avg(dcload) + [$DCenter set avgLoad_]]

  # Load of individual servers
  for {set k 0} {$k < $top(NServers)} {incr k} {
    set avg(servload-$k) [expr $avg(servload-$k) + 0.0 + [$hosts_($k) set currentLoad_]]
    set avg(servloadmem-$k) [expr $avg(servloadmem-$k) + 0.0 + [$hosts_($k) set currentLoadMem_]]
    set avg(servloadstor-$k) [expr $avg(servloadstor-$k) + 0.0 + [$hosts_($k) set currentLoadStor_]]
  }
	
# Load of individual VMs
for {set k 0} {$k < $virt(NVms)} {incr k} {
  set avg(vmload-$k) [expr $avg(vmload-$k) + 0.0 + [$vms_($k) set currentLoad_]]
  set avg(vmloadmem-$k) [expr $avg(vmloadmem-$k) + 0.0 + [$vms_($k) set currentLoadMem_]]
  set avg(vmloadstor-$k) [expr $avg(vmloadstor-$k) + 0.0 + [$vms_($k) set currentLoadStor_]]
}
	
  # Server load over time
  puts $graph(serv_load_time) "$now [$hosts_($mon(serv)) set currentLoad_]"
	

  # Load of individual links
  set bdepartures [$qmon_hosts_C3_($mon(link_hosts_C3)) set bdepartures_]
  set lutil [expr $bdepartures*8*100/$sim(interval)/$top(bw_C3H)]	
  $qmon_hosts_C3_($mon(link_hosts_C3)) set bdepartures_ 0
  puts $graph(linkHC3_load_time) "$now $lutil"

  # Queue size on Hosts-C3 links
  set pkts [$qmon_hosts_C3_($mon(queue-HC3)) set pkts_]
  puts $graph(QueueHC3_pkts) "$now $pkts"

  for {set k 0} {$k < $top(NServers)} {incr k} {
    set avg(queueHC3_pkts-$k) [expr $avg(queueHC3_pkts-$k) + 0.0 + [$qmon_hosts_C3_($k) set pkts_]]
  }

  # Queue size on C3-C2 links
  set pkts [$qmon_C3_C2_($mon(queue-C3C2)-0) set pkts_]
  puts $graph(QueueC3C2-0_pkts) "$now $pkts"
	
  incr avg(samples)
      
  $ns at [expr $now + $sim(interval)] "record_graphs"
}

#Open graph files
set graph(DCload) [open "$dir(traces)/dcLoad.tr" w]
set graph(DCloadMem) [open "$dir(traces)/dcLoadMem.tr" w]
set graph(DCloadStor) [open "$dir(traces)/dcLoadStor.tr" w]
set graph(DCpower) [open "$dir(traces)/dcPower.tr" w]
set graph(eServers) [open "$dir(traces)/eServers.tr" w]
set graph(LinkC1C2_load) [open "$dir(traces)/link_C1C2_load.tr" w]
set graph(LinkC2C1_load) [open "$dir(traces)/link_C2C1_load.tr" w]
set graph(LinkC2C3_load) [open "$dir(traces)/link_C2C3_load.tr" w]
set graph(LinkC3C2_load) [open "$dir(traces)/link_C3C2_load.tr" w]
set graph(LinkC3H_load) [open "$dir(traces)/link_C3H_load.tr" w]
set graph(LinkHC3_load) [open "$dir(traces)/link_HC3_load.tr" w]
set graph(eCoreSwitches) [open "$dir(traces)/eCoreSwitches.tr" w]
set graph(eAggrSwitches) [open "$dir(traces)/eAggrSwitches.tr" w]
set graph(eAccessSwitches) [open "$dir(traces)/eAccessSwitches.tr" w]
set graph(dcServTasks) [open "$dir(traces)/dcServTasks.tr" w]
set graph(dcServTasksFailed) [open "$dir(traces)/dcServTasksFailed.tr" w]
set graph(dcServLoad) [open "$dir(traces)/dcServLoad.tr" w]
set graph(dcServLoadMem) [open "$dir(traces)/dcServLoadMem.tr" w]
set graph(dcServLoadStor) [open "$dir(traces)/dcServLoadStor.tr" w]
set graph(dcVmLoad) [open "$dir(traces)/dcVmLoad.tr" w]
set graph(dcVmLoadMem) [open "$dir(traces)/dcVmLoadMem.tr" w]
set graph(dcVmLoadStor) [open "$dir(traces)/dcVmLoadStor.tr" w]
set graph(dcVmTasks) [open "$dir(traces)/dcVmTasks.tr" w]
set graph(dcVmTasksFailed) [open "$dir(traces)/dcVmTasksFailed.tr" w]
set graph(linkHC3_load_time) [open "$dir(traces)/link_HC3_load_time.tr" w]
set graph(serv_load_time) [open "$dir(traces)/serv_load_time.tr" w]
set graph(QueueHC3_pkts) [open "$dir(traces)/queue_HC3_pkts_time.tr" w]
set graph(QueueC3C2-0_pkts) [open "$dir(traces)/queue_C3C2-0_pkts.tr" w]
set graph(queueHC3-pkts-avg) [open "$dir(traces)/queue_HC3_pkts_avg.tr" w]
set graph(users) [open "$dir(traces)/users.tr" w]



#General purpose logging files (used for the dashboard)
set graph(energySummary) [open "$dir(traces)/energySummary.tr" w]
set graph(loadSummary) [open "$dir(traces)/loadSummary.tr" w]
set graph(taskSummary) [open "$dir(traces)/taskSummary.tr" w]
set graph(parameters) [open "$dir(traces)/parameters.tr" w]
set graph(simulation) [open "$dir(traces)/simulation.tr" w]
