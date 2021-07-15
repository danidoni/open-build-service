FactoryBot.define do
  factory :workflow do
    workflow do
      {"steps"=>[{"branch_package"=>{"source_project"=>"OBS:Server:Unstable", "source_package"=>"obs-server"}}],
    "filters"=>{"architectures"=>{"only"=>["x86_64"]}, "repositories"=>{"only"=>["openSUSE_Factory", "openSUSE_15.1", "SLE_15_SP1", "SLE_15_SP3"]}}}}
    end
    scm_extractor_payload do
      {
        scm_extractor_payload: {
          scm: scm,
          event: event,
          action: action
        }
      }
    end
    token { create(:workflow_token) }
  end
end