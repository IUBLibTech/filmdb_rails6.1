Rails.application.routes.draw do

  get '/ajax/title_date/type/', to: 'ajax#title_date_type', as: 'ajax_title_date_type'
  get '/ajax/title_genre/genre/', to: 'ajax#title_genre', as: 'ajax_title_genre'
  get '/ajax/title_form/form', to: 'ajax#title_form', as: 'ajax_title_form'
  get '/ajax/title_creator/role', to: 'ajax#title_creator_role', as: 'ajax_title_creator_role'
  get '/ajax/title_publisher/role', to: 'ajax#title_publisher_role', as: 'ajax_publisher_role'
  get '/ajax/title_original_identifier/type', to: 'ajax#title_original_identifier', as: 'ajax_title_original_identifier'

  get '/alf/upload_barcodes', to: 'alf#barcode_upload', as: 'alf_barcode_upload'
  post '/alf/process_upload_barcodes', to: 'alf#process_barcode_upload', as: 'alf_process_barcode_upload'

  resources :cages
  get '/cages/cage_shelf/:id/ajax_physical_objects', to: 'cages#shelf_physical_objects', as: 'cage_shelf_physical_objects'
  post '/cages/cage_shelf/:id/ajax_physical_objects/', to: 'cages#add_physical_object_to_shelf', as: 'add_physical_object_to_cage_shelf_post'
  patch '/cages/cage_shelf/:id/ajax_physical_objects/', to: 'cages#add_physical_object_to_shelf', as: 'add_physical_object_to_cage_shelf_patch'
  delete '/cages/cage_shelf/:id/ajax_remove_physical_object_from_shelf/:po_id', to: 'cages#remove_physical_object', as: 'remove_physical_object_from_shelf'
  get '/cages/:id/show_xml', to: 'cages#show_xml', as: 'show_cage_xml'
  post '/cages/mark_ready_to_ship/:id', to: 'cages#mark_ready_to_ship', as: 'mark_ready_to_ship'
  post '/cages/unmark_ready_to_ship/:id', to: 'cages#unmark_ready_to_ship', as: 'unmark_ready_to_ship'
  post '/cages/mark_shipped/:id', to: 'cages#mark_shipped', as: 'mark_shipped'
  get '/cages/push_result/:id', to: 'cages#push_result', as: 'cage_push_result'
  get '/cages/cage_shelf/:id/ajax_cage_shelf_stats', to: 'cages#ajax_cage_shelf_stats', as: 'ajax_cage_shelf_stats'
  get '/cages/ajax_add_physical_object_iu_barcode_scan/:iu_barcode', to: 'cages#ajax_add_physical_object_iu_barcode_scan', as: 'ajax_add_physical_object_iu_barcode_scan'

  get '/cage_shelves', to: 'cage_shelves#index', as: 'cage_shelves'
  get '/cage_shelves/:id', to: 'cage_shelves#show', as: 'cage_shelf'
  get '/cage_shelf/memnon_digiprov/:id', to: 'cage_shelves#get_digiprov', as: 'get_digiprov'

  resources :collections
  #get '/collections/:id/new_physical_object', to: 'collections#new_physical_object', as: 'collection_new_physical_object'
  #post 'collections/:id/create_physical_object', to: 'collections#create_physical_object', as: 'collection_create_physical_object'
  get '/autocomplete_collection/', to: 'collections#autocomplete_collection', as: 'autocomplete_collection'
  get '/autocomplete_collection_for_unit/:unit_id', to: 'collections#autocomplete_collection_for_unit', as: 'autocomplete_collection_for_uni'



  #post '/component_groups/create/:title_id', to: 'component_groups#create', as: 'component_group'
  get '/component_groups/ajax/:id', to: 'component_groups#ajax_physical_objects_list', as: 'ajax_physical_objects_list'
  post '/component_groups/:id/ajax/remove_physical_object/:pid', to:'component_groups#remove_physical_object', as: 'remove_physical_object_from_component_group'
  post '/component_groups/:id/add_to_component_group/', to: 'component_groups#add_physical_objects', as: 'add_physical_objects_to_component_group'
  post '/component_groups/:id/ajax_queue_pull_request', to: 'component_groups#ajax_queue_pull_request', as: 'ajax_queue_pull_request'
  post '/component_groups/:id/ajax_move_into_active_request', to: 'component_groups#ajax_move_into_active_request', as: 'ajax_move_into_active_request'
  post '/component_groups/:id/ajax_edit_summary', to:'component_groups#ajax_edit_summary', as: 'ajax_edit_summary'

  resources :controlled_vocabularies
  #get '/inventory/', to: 'physical_objects#new', as: 'inventory'

  resources :physical_objects
  post '/physical_objects', to: 'physical_objects#create', as: 'create_physical_object'
  get '/physical_objects_filter', to: 'physical_objects#index', as: 'physical_objects_filter_default'
  get '/physical_objects/dup/:id', to: 'physical_objects#duplicate', as: 'duplicate_physical_object'
  post '/physical_objects/create_duplicate', to: 'physical_objects#create_duplicate', as: 'create_duplicate_physical_object'
  get '/physical_object_ad_strip', to: 'physical_objects#edit_ad_strip', as: 'edit_ad_strip'
  post '/physical_object_ad_strip', to: 'physical_objects#update_ad_strip', as: 'update_ad_strip'
  get '/physical_object_location', to: 'physical_objects#edit_location', as: 'edit_location'
  patch '/physical_objects/:id/edit', to: 'physical_objects#edit', as: 'edit_physical_object_medium'

  get '/equipment_technology/', to: 'physical_objects#equipment_technology', as: 'equipment_technology'

  #post '/physical_object_location', to: 'physical_objects#update_location', as: 'update_location'
  get '/test_email/', to: 'physical_objects#test_email', as: 'test_email'
  get '/physical_objects/show_xml/:id', to: 'physical_objects#show_xml', as: 'show_physical_object_xml'
  get '/physical_objects/ajax_show_storage/:iu_barcode', to: 'physical_objects#ajax_show_storage', as: 'ajax_show_storage'
  get '/physical_objects/workflow_history/:id', to: 'physical_objects#workflow_history', as: 'physical_object_workflow_history'
  post '/physical_objects/mark_missing/:id', to: 'physical_objects#mark_missing', as: 'physical_object_mark_missing'
  get '/physical_objects/digiprov/:id', to: 'physical_objects#digiprovs', as: 'digiprovs'
  get '/physical_objects/ajax_belongs_to_title/:iu_barcode/:title_id', to: 'physical_objects#ajax_belongs_to_title?', as: 'ajax_physical_object_belongs_to_title'
  get '/physical_objects/:id/ajax_lookup_barcode', to: 'physical_objects#ajax_lookup_barcode', as: 'ajax_lookup_barcode'
  post '/physical_objects/ajax/rebuild_form', to: 'physical_objects#ajax_rebuild_form', as: 'physical_objects_ajax_rebuild_form'

  # physical objects have to render the form based on a Medium (film, video, etc). When a users enters data THEN changes
  # the Medium, we need to POST the already entered data to the original action (#new or #edit).
  post '/physical_objects/:id/edit', to: 'physical_objects#edit', as: 'physical_objects_edit_post'
  post '/physical_objects/new', to: 'physical_objects#new', as: 'physical_objects_new_post'
  post '/physical_objects/:id', to: 'physical_objects#update', as: 'physical_object_update'
  get '/compilations', to: 'physical_objects#compilations', as: 'compilations'
  get '/compilations/:comp', to: 'physical_objects#compilation_physical_objects', as: 'compilation_physical_objects'

  # pod_pushes
  get '/pod_pushes', to: 'pod_pushes#index', as: 'pod_pushes'
  get '/pod_pushes/:id', to: 'pod_pushes#show', as: 'pod_push'

  # pull requests
  get '/pull_requests', to: 'pull_requests#index', as: 'pull_requests'
  get '/pull_requests/:id', to: 'pull_requests#show', as: 'show_pull_request'

  get '/search', to: 'search#search', as: 'barcode_search'

  resources :series
  get '/series/:id/new_physical_object', to: 'series#new_physical_object', as: 'series_new_physical_object'
  post 'series/:id/create_physical_object', to: 'series#create_physical_object', as: 'series_create_physical_object'
  get '/autocomplete_series/', to: 'series#autocomplete_series', as: 'autocomplete_series'
  get '/series/ajax/show/:id', to: 'series#ajax_show_series', as: 'ajax_show_series'
  get '/series/merge/merge_series', to: 'series#show_merge_series', as: 'show_merge_series'
  post '/series/merge/merge_selected_series', to: 'series#series_auto_complete_selection_merge', as: 'series_autocomplete_selection_merge'
  get '/series/merge/series_table_row/:id', to: 'series#ajax_series_merge_table_row', as: 'ajax_series_merge_table_row'

  # services URLs
  post '/services/update_batch/:bin_barcode', to: 'services#receive', as: 'update_batch'
  get '/services/update_batch/:bin_barcode', to: 'services#receive', as: 'update_batch_test'
  post '/services/push_cage_to_pod/:cage_id', to: 'services#show_push_cage_to_pod_xml', as: 'show_push_cage_to_pod_xml'
  get '/services/test_pod_connection', to: 'services#test_basic_auth', as: 'test_basic_auth'
  get '/services/mods/:mdpi_barcode', to: 'services#mods_from_barcode', as: 'mods_service'

  resources :spreadsheets, only: [:index, :show, :destroy]
  post '/spreadsheets', to: 'spreadsheets#upload', as: 'spreadsheet_upload'
  get '/spreadsheets/:id/title/:title', to: 'spreadsheets#merge_title_candidates', as: 'merge_title_candidates'
  post 'spreadsheets/:id/merge_title', to: 'spreadsheets#merge_titles', as: 'merge_spreadsheet_titles'
  get '/spreadsheets/:id/series/:series', to: 'spreadsheets#merge_series_candidates', as: 'merge_series_candidates'
  post '/spreadsheets/:id/merge_series', to: 'spreadsheets#merge_series', as: 'merge_series'

  resources :spread_sheet_searches, only: [:index, :destroy]
  get '/spreadsheet_search/download/:id', to: "spread_sheet_searches#download", as: "spreadsheet_search_download"
  get '/spreadsheet_search/ajax/progress/', to: "spread_sheet_searches#check_progress", as: "spreadsheet_search_progress"


  get '/stats/', to: 'stats#index', as: 'stats_index'
	post '/stats/', to: 'stats#filter_index', as: 'stats_filter_index'
	get '/stats/empty_titles/:unit/:collection_id/:start/:end', to: 'stats#empty_titles', as: 'empty_title'
	get '/stats/empty_series/:unit/:collection_id/:start/:end', to: 'stats#empty_series', as: 'empty_series'
  get '/stats/ajax/medium_stats', to: 'stats#ajax_medium_stats', as: 'ajax_medium_stats'

  resources :titles, except: [:index] do
    resources :component_groups, only: [] do
      get 'best_copy_selection'
      post 'best_copy_selection_update', to: 'component_groups#best_copy_selection_create', as: 'best_copy_selection_create'
      get 'ajax_best_copy_selection_membership/:iu_barcode', to: 'component_groups#ajax_best_copy_selection_membership', as: 'ajax_best_copy_selection_membership'
    end
  end

  get '/titles/filter_selected/:selected', to: 'titles#index', as: 'selected_titles'
  get '/titles/:id/new_physical_object', to: 'titles#new_physical_object', as: 'title_new_physical_object'
  post 'titles/:id/create_physical_object', to: 'titles#create_physical_object', as: 'titles_create_physical_object'
  get '/titles/:id/show_split_title', to: 'titles#split_title', as: 'show_split_title'
  get '/titles/:id/component_groups/new', to: 'component_groups#new', as: 'new_title_component_group'
  post '/titles/:id/component_groups/create', to: 'component_groups#create', as: 'create_title_component_group'
  delete '/titles/:t_id/component_groups/delete/:id', to: 'component_groups#destroy', as: 'delete_component_group'
  get '/titles/:t_id/component_groups/:id', to: 'component_groups#edit', as: 'edit_component_group'
  patch '/titles/:t_id/component_groups/:id', to: 'component_groups#update', as: 'update_component_group'
  get '/titles/:t_id/component_groups/:id/mdpi', to: 'component_groups#move_to_mdpi_workflow', as: 'move_to_mdpi_workflow'
  post '/titles/:t_id/component_groups/:id/mdpi_create', to: 'component_groups#move_to_mdpi_workflow_create', as: 'move_to_mdpi_workflow_create'
  get '/titles/ajax/:id', to:'titles#ajax_summary', as: 'title_ajax'
  get '/titles/ajax/new/:series_id', to: 'titles#new_ajax', as: 'new_title_ajax'
  post '/titles/ajax/new_title', to: 'titles#create_ajax', as: 'create_title_ajax'
  post '/titles/create_component_group/:id', to: 'titles#create_component_group', as: 'create_component_group'
  get '/autocomplete_title/', to: 'titles#autocomplete_title', as: 'autocomplete_title'
  get '/autocomplete_title_for_series/:series_id/', to: 'titles#autocomplete_title_for_series', as: 'autocomplete_title_for_series'
  get '/titles/', to: 'titles#search', as: 'titles_index'
  get '/search/titles', to: 'titles#search', as: 'titles_search_index'
  post '/search/titles', to: 'titles#search', as: 'titles_search'
  get '/titles/ajax/edit_cg_params/:id', to: 'titles#ajax_edit_cg_params', as: 'ajax_edit_cg_params'
  post '/titles/merge', to: 'titles#titles_merge', as: 'titles_merge'
  post '/titles/do_merge', to: 'titles#merge_titles', as: 'merge_titles'
  get '/title_merge_selection/', to: 'titles#title_merge_selection', as: 'title_merge_selection'
  get '/title_merge_selection_table_row/:id', to: 'titles#title_merge_selection_table_row', as: 'title_merge_selection_table_row'
  get '/title_merge_selection/merge_physical_object_candidates', to: 'titles#merge_physical_object_candidates', as: 'title_merge_physical_object_candidates'
  post '/title_merge_select/merge_titles', to: 'titles#merge_autocomplete_titles', as: 'title_autocomplete_selection_merge'
  post '/titles/ajax_split_title_cg_table', to: 'titles#split_title_cg_table', as: 'split_title_cg_table'
  post '/titles/:id/update_split_title', to: 'titles#update_split_title', as: 'update_split_title'
  get '/titles/ajax_reel_count/:id', to: 'titles#ajax_reel_count', as: 'ajax_reel_count'
  get '/titles/merge/in_storage', to: 'titles#merge_in_storage', as: 'merge_in_storage'
  post '/titles/merge/in_storage_update', to: 'titles#merge_in_storage_update', as: 'merge_in_storage_update'
  get '/titles/search/csv_search', to: 'titles#csv_search', as: 'title_csv_search'

  # the link that generates a SpreadSheetSearch object so we need to prevent browser back/forward buttons re-creating
  # the object multiple times. The :ts value should be based on Process.clock_gettime(Process::CLOCK_MONOTONIC) for accuracy
  get '/titles/search/xls_search/', to: 'titles#xls_search', as: 'title_xls_search'
  resources :units

  resources :users
  get '/users/worksite_location/:id', to: 'users#show_update_location', as: 'show_worksite_location'
  patch '/users/worksite_location/:id', to: 'users#update_location', as: 'update_worksite_location'
  get '/user_deleters', to: 'users#deleters', as: 'deleters'

  # routes for workflow
  get '/workflow/pull_request', to: 'workflow#pull_request', as: 'pull_request'
  post '/workflow/process_pull_request', to: 'workflow#process_pull_requested', as: 'process_pull_requested'
  get '/workflow/receive_from_storage', to: 'workflow#receive_from_storage', as: 'receive_from_storage'
  patch '/workflow/receive_from_storage/', to: 'workflow#process_receive_from_storage', as: 'process_received_from_storage'
  post '/workflow/receive_from_storage_wells/', to: 'workflow#process_receive_from_storage_wells', as: 'process_received_from_storage_wells'
  get '/workflow/ajax_alf_barcode/:iu_barcode', to: 'workflow#ajax_alf_receive_iu_barcode', as: 'ajax_alf_receive_iu_barcode'
  get '/workflow/ajax_wells_barcode/:iu_barcode', to: 'workflow#ajax_wells_receive_iu_barcode', as: 'ajax_wells_receive_iu_barcode'
  get '/workflow/ship_external', to: 'workflow#ship_external', as: 'ship_external'
  get '/workflow/receive_external', to: 'workflow#receive_from_external', as: 'receive_external'
  get '/workflow/return_to_storage', to: 'workflow#return_to_storage', as: 'return_to_storage'
  post '/workflow/return_to_storage', to: 'workflow#process_return_to_storage', as: 'process_return_to_storage'
  get '/workflow/send_for_mold_abatement', to: 'workflow#send_for_mold_abatement', as: 'send_for_mold_abatement'
  post '/workflow/process_send_for_mold_abatement', to: 'workflow#process_send_for_mold_abatement', as: 'process_send_for_mold_abatement'
  get '/workflow/send_to_freezer', to: 'workflow#send_to_freezer', as: 'send_to_freezer'
  post '/workflow/process_send_to_freezer', to: 'workflow#process_send_to_freezer', as: 'process_send_to_freezer'
  get '/workflow/mark_missing', to: 'workflow#mark_missing', as: 'mark_missing'
  post '/workflow/process_mark_missing', to: 'workflow#process_mark_missing', as: 'process_mark_missing'
  post '/workflow/ajax_cancel_queued_pull_request/:id', to: 'workflow#ajax_cancel_queued_pull_request', as: 'cancel_queued_pull_request'
  get '/workflow/best_copy_selection', to: 'workflow#best_copy_selection', as: 'workflow_best_copy_selection'
  post '/workflow/ajax_best_copy_selection_barcode/:iu_barcode', to: 'workflow#ajax_best_copy_selection_barcode', as: 'ajax_best_copy_selection_barcode'
  get '/workflow/ajax_best_copy_selection_barcode/:iu_barcode',  to: 'workflow#ajax_best_copy_selection_barcode', as: 'ajax_best_copy_selection_barcode_test'
  #post '/workflow/best_copy_selection_update', to: 'workflow#best_copy_selection_update', as: 'best_copy_selection_update'
  get '/workflow/issues_shelf', to: 'workflow#issues_shelf', as: 'issues_shelf'
  post '/workflow/ajax_issues_shelf_barcode/:iu_barcode', to: 'workflow#ajax_issues_shelf_barcode', as: 'ajax_issues_shelf_barcode'
  patch '/workflow/ajax_issues_shelf_update/:id', to: 'workflow#ajax_issues_shelf_update', as: 'ajax_issues_shelf_update'
  get '/workflow/update_location', to: 'workflow#update_location', as: 'update_location'
  get '/workflow/ajax_update_location_get/:barcode', to: 'workflow#ajax_update_location', as: 'ajax_update_location_get'
  post '/workflow/ajax_update_location_post', to: 'workflow#ajax_update_location_post', as: 'ajax_update_location_post'
  get '/workflow/cancel_after_pull_request', to: 'workflow#cancel_after_pull_request', as: 'cancel_after_pull_request'
  post '/workflow/process_cancel_after_pull_request/:id', to: 'workflow#process_cancel_after_pull_request', as: 'process_cancel_after_pull_request'
  post '/workflow/process_requeue_after_pull_request/:id', to: 'workflow#process_requeue_after_pull_request', as: 'process_requeue_after_pull_request'
  get '/workflow/return_from_mold_abatement/', to: 'workflow#return_from_mold_abatement', as: 'return_from_mold_abatement'
  get '/workflow/ajax_mold_abatement_barcode/:bc', to: 'workflow#ajax_mold_abatement_barcode', as: 'ajax_mold_abatement_barcode'
  post '/workflow/update_return_from_mold_abatement/:id', to: 'workflow#update_return_from_mold_abatement', as: 'update_return_from_mold_abatement'

  #get '/workflow/ajax_mark_found/:iu_barcode', to: 'workflow#ajax_mark_found', as: 'ajax_mark_found'

  get '/workflow/update_mark_found', to: 'workflow#show_mark_found', as: 'show_mark_found'
  post '/workflow/update_mark_found', to: 'workflow#update_mark_found', as: 'update_mark_found'
  get '/workflow/ajax_mark_found_lookup/', to: 'workflow#ajax_mark_found_lookup', as: 'ajax_mark_found_lookup'
  get '/workflow/ajax_load_found_selection_table/', to: 'workflow#ajax_load_found_selection_table', as: 'ajax_load_found_selection_table'
  get '/workflow/ajax/load_found_cg_table', to: 'workflow#ajax_load_found_cg_table', as: 'ajax_load_found_cg_table'
  post '/workflow/choose_found_workflow/', to: 'workflow#choose_found_workflow', as: 'choose_found_workflow'

  get '/workflow/digitization_staging_list', to: 'workflow#digitization_staging_list', as: 'digitization_staging_list'
  get '/workflow_statuses', to: 'workflow_statuses#index', as: 'workflow_statuses'
  get '/workflow/ajax_show_storage_location/:iu_barcode', to: 'workflow#ajax_return_to_storage_lookup', as: 'ajax_return_to_storage_lookup'
  get '/workflow/correct_freezer_loc', to: 'workflow#correct_freezer_loc_get', as: 'correct_freezer_loc_get'
  post '/workflow/correct_freezer_loc', to: 'workflow#correct_freezer_loc_post', as: 'correct_freezer_loc_post'
  get '/workflow/deaccession', to: 'workflow#deaccession', as: 'deaccession'
  post '/workflow/deaccession', to: 'workflow#deaccession_ajax_post', as: 'deaccession_ajax_post'
  # workflow_stats routes
  get '/workflow_stats/digitization_staging_stats', to: 'workflow_stats#digitization_staging_stats', as: 'digitization_staging_stats'
  get '/workflow_stats/shipped_so_far', to: 'workflow_stats#shipped_so_far', as: 'shipped_so_far'

  match '/signin', to: 'sessions#new', via: :get
  match '/signout', to: 'sessions#destroy', via: :delete

  resources :sessions, only: [:new, :destroy] do
    get :validate_login, on: :collection
  end

  root "titles#index"
end
