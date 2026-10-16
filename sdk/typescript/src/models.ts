export interface Version {
  kb_version: string;
  api_version: string;
  schema_version: string;
  built_at: string;
}

export interface SearchResult {
  id: string;
  title: string;
  domain: string;
  difficulty: string;
  safety: string;
  score: number;
  snippet?: string;
}

export interface EntrySummary {
  id: string;
  title: string;
  domain: string;
  difficulty: string;
  safety: string;
  verification_status: string;
}

export interface Entry extends EntrySummary {
  tags: string[];
  body: string;
  metadata: Record<string, unknown>;
}

export interface Edge {
  id: string;
  relation: "prerequisite" | "material" | "tool" | "link" | "translation";
}

export interface LinkGraph {
  id: string;
  outgoing: Edge[];
  incoming: Edge[];
}

export interface Verification {
  entry_id: string;
  status: "draft" | "peer-reviewed" | "field-tested" | "deprecated";
  reviewers: string[];
  tested_by?: string | null;
  tested_date?: string | null;
  tested_location?: string | null;
  notes?: string;
}

export interface VerificationEvent {
  entry_id: string;
  from_status: string;
  to_status: string;
  actor: string;
  timestamp: string;
  notes?: string;
}

export interface FieldTest {
  [k: string]: unknown;
}

export interface Stats {
  total: number;
  by_status: Record<string, number>;
  by_domain: Record<string, number>;
  by_safety: Record<string, number>;
  by_difficulty: Record<string, number>;
}

export interface Resolution {
  uri: string;
  node_id: string;
  api_url: string;
  entry_id: string;
  title: string;
}
