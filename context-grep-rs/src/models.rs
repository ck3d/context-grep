use serde::Serialize;

#[derive(Serialize)]
pub struct MatchResult {
    pub file: String,
    #[serde(rename = "match")]
    pub match_info: NodeInfo,
    pub target: Option<NodeInfo>,
    pub context: Vec<NodeInfo>,
    pub filetype: String,
}

#[derive(Serialize)]
pub struct NodeInfo {
    pub text: String,
    pub line: usize,
    #[serde(rename = "type")]
    pub node_type: String,
    pub language: String,
}

#[derive(Clone, Copy)]
pub enum Role {
    Match,
    Target,
    Context,
}

pub struct StyledNode<'a> {
    pub node: &'a NodeInfo,
    pub role: Role,
}
