################################################################################
## NEAMS Micro-Reactor Application Driver                                     ##
## Heat Pipe Microreactor Steady State                                        ##
## Griffin Main Application input file                                        ##
## CFEM-SN (1, 3)                                                             ##
################################################################################

[Mesh]
  [loader]
    type = FileMeshGenerator
    file = '../mesh/gold/HPMR_OneSixth_Core_meshgenerator_tri_rotate_bdry.e'
  []
  [id]
    type = SubdomainExtraElementIDGenerator
    input = loader
    subdomains = '200 203 100 103 301 303 10 503 600 601 201 101 400 401 250'
    extra_element_id_names = 'material_id equivalence_id'
    extra_element_ids = '815 815 802 802 801 801 803 811 820 820 817 816 805 805 820;
                         815 815 802 802 801 801 803 811 820 820 817 816 805 805 820'
  []
  uniform_refine = 0
[]

[Executioner]
  type = PicardEigen

  automatic_scaling = true
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart '
  petsc_options_value = 'hypre boomeramg 100'

  free_power_iterations = 1
  output_after_power_iterations = 0
  output_before_normalization = 0

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8

  nl_max_its = 100
  l_tol = 1e-2
  picard_rel_tol = 1.0e-06
  picard_abs_tol = 1.0e-08
  picard_max_its = 10
  disable_picard_residual_norm_check = false
[]

[TransportSystems]
  particle = neutron
  equation_type = eigenvalue

  G = 11
  VacuumBoundary = '10000 2000 3000'
  ReflectingBoundary = '147'

  [sn]
    scheme = SAAF-CFEM-SN
    family = LAGRANGE
    order = FIRST
    fission_source_as_material = true
    n_delay_groups = 6
    AQtype = Gauss-Chebyshev
    NPolar = 1
    NAzmthl = 3
    NA = 2
    tau = 0.5
  []
[]

[AuxVariables]
  [Tf]
    initial_condition = 873.15
    order = CONSTANT
    family = MONOMIAL
  []
  [Tm]
    initial_condition = 873.15
    order = CONSTANT
    family = MONOMIAL
  []
[]

[GlobalParams]
  library_file = '../isoxml/fullcore_xml_G11_endfb8_ss_tr.xml'
  library_name = fullcore_xml_G11_endfb8_ss_tr
  isotopes = 'pseudo'
  densities = 1.0
  is_meter = true
  plus = true
  dbgmat = false
  grid_names = 'Tfuel Tmod'
  grid_variables = 'Tf Tm'
[]

[Materials]
  [mod]
    type = CoupledFeedbackMatIDNeutronicsMaterial
    block = '200 203 100 103 301 303 10 503 600 601 201 101 400 401 250'
  []
[]

[PowerDensity]
  power = 345.6e3
  power_density_variable = power_density
  integrated_power_postprocessor = integrated_power
[]

[MultiApps]
  [bison]
    type = FullSolveMultiApp
    positions = '0 0 0'
    input_files = HPMR_thermo_ss.i
    execute_on = 'timestep_end'
    keep_solution_during_restore = true
  []
[]

[Transfers]
  [to_sub_power_density]
    type = MultiAppProjectionTransfer
    direction = to_multiapp
    multi_app = bison
    variable = power_density
    source_variable = power_density
    execute_on = 'initial timestep_end'
    displaced_source_mesh = false
    displaced_target_mesh = false
    use_displaced_mesh = false
  []
  [from_sub_temp_fuel]
    type = MultiAppInterpolationTransfer
    direction = from_multiapp
    multi_app = bison
    variable = Tf
    source_variable = Tfuel
    execute_on = 'initial timestep_end'
    displaced_source_mesh = false
    displaced_target_mesh = false
    use_displaced_mesh = false
    num_points = 1 # interpolate with one point (~closest point)
    power = 0 # interpolate with constant function
  []
  [from_sub_temp_mod]
    type = MultiAppInterpolationTransfer
    direction = from_multiapp
    multi_app = bison
    variable = Tm
    source_variable = Tmod
    execute_on = 'initial timestep_end'
    displaced_source_mesh = false
    displaced_target_mesh = false
    use_displaced_mesh = false
    num_points = 1 # interpolate with one point (~closest point)
    power = 0 # interpolate with constant function
  []
[]

[Postprocessors]
  [scaled_power_avg]
    type = ElementAverageValue
    block = 'fuel_quad fuel_tri'
    variable = power_density
    execute_on = 'initial timestep_end'
  []
  [fuel_temp_avg]
    type = ElementAverageValue
    variable = Tf
    block = 'fuel_quad fuel_tri'
    execute_on = 'initial timestep_end'
  []
  [fuel_temp_max]
    type = ElementExtremeValue
    value_type = max
    variable = Tf
    block = 'fuel_quad fuel_tri'
    execute_on = 'initial timestep_end'
  []
  [fuel_temp_min]
    type = ElementExtremeValue
    value_type = min
    variable = Tf
    block = 'fuel_quad fuel_tri'
    execute_on = 'initial timestep_end'
  []
  [mod_temp_avg]
    type = ElementAverageValue
    variable = Tm
    block = 'moderator_quad moderator_tri'
    execute_on = 'initial timestep_end'
  []
  [mod_temp_max]
    type = ElementExtremeValue
    value_type = max
    variable = Tm
    block = 'moderator_quad moderator_tri'
    execute_on = 'initial timestep_end'
  []
  [mod_temp_min]
    type = ElementExtremeValue
    value_type = min
    variable = Tm
    block = 'moderator_quad moderator_tri'
    execute_on = 'initial timestep_end'
  []
[]

[Outputs]
  csv = true
  exodus = true
  perf_graph=true
[]
