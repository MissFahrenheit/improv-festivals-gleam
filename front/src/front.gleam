import festival as festival_shared
import festivals_html
import gleam/json
import gleam/result
import lustre
import plinth/browser/document
import plinth/browser/element as plinth_element
import types

pub fn main() {
  let assert Ok(json) =
    document.query_selector("#model")
    |> result.map(plinth_element.inner_text)

  let assert Ok(model) = json.parse(json, festival_shared.model_decoder())
  let app = lustre.simple(init, update, festivals_html.view)

  let assert Ok(_) = lustre.start(app, "#app", model)
}

// Start on the tab the server rendered as active (the first sheet tab), so
// the page doesn't jump when the script takes over.
fn init(model: types.Model) -> types.Model {
  model
}

fn update(model: types.Model, msg: types.Msg) -> types.Model {
  case msg {
    types.UserClickedTab(tab_id) -> change_tab(model, tab_id)
  }
}

fn change_tab(model: types.Model, tab_id: String) -> types.Model {
  types.Model(..model, active_tab: tab_id)
}
