import festival as festival_shared
import festivals_html
import gleam/json
import gleam/result
import lustre
import plinth/browser/document
import plinth/browser/element as plinth_element
import types.{type Continent, type Festival}

pub fn main() {
  let assert Ok(json) =
    document.query_selector("#model")
    |> result.map(plinth_element.inner_text)

  let assert Ok(model) = json.parse(json, festival_shared.model_decoder())
  let app = lustre.simple(init, update, festivals_html.view)

  let assert Ok(_) =
    lustre.start(app, "#app", #(model.festivals, model.continents))
}

fn init(data: #(List(Festival), List(Continent))) {
  types.Model(active_tab: "europe", festivals: data.0, continents: data.1)
}

fn update(model: types.Model, msg: types.Msg) -> types.Model {
  case msg {
    types.UserClickedTab(tab_id) -> change_tab(model, tab_id)
  }
}

fn change_tab(model: types.Model, tab_id: String) -> types.Model {
  types.Model(..model, active_tab: tab_id)
}
