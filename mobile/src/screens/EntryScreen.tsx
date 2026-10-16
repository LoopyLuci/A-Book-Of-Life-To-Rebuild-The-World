import React, { useEffect, useState } from "react";
import { View, Text, ScrollView, StyleSheet } from "react-native";
import { getEntry, EntryRow } from "../db";

export default function EntryScreen({ route }: any) {
  const { id } = route.params;
  const [entry, setEntry] = useState<EntryRow | null>(null);

  useEffect(() => {
    getEntry(id).then(setEntry);
  }, [id]);

  if (!entry) return <View style={styles.container}><Text>Loading…</Text></View>;

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>{entry.title}</Text>
      <Text style={styles.meta}>
        {entry.domain} · {entry.difficulty} · {entry.safety} · {entry.verification_status}
      </Text>
      <Text style={styles.body}>{entry.body}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: "#fafaf7" },
  title: { fontSize: 22, fontWeight: "700", marginBottom: 6 },
  meta: { fontSize: 13, color: "#666", marginBottom: 16 },
  body: { fontSize: 15, lineHeight: 22 },
});
