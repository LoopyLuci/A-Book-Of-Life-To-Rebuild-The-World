import React, { useState, useCallback } from "react";
import {
  View, Text, TextInput, FlatList, TouchableOpacity, StyleSheet,
} from "react-native";
import { searchEntries, EntryRow } from "../db";

export default function HomeScreen({ navigation }: any) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<EntryRow[]>([]);

  const doSearch = useCallback(async (q: string) => {
    setQuery(q);
    if (q.trim().length < 2) {
      setResults([]);
      return;
    }
    const rows = await searchEntries(q.trim());
    setResults(rows);
  }, []);

  return (
    <View style={styles.container}>
      <TextInput
        style={styles.input}
        placeholder="Search A Book Of Life…"
        value={query}
        onChangeText={doSearch}
        autoCorrect={false}
      />
      <FlatList
        data={results}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.row}
            onPress={() => navigation.navigate("Entry", { id: item.id })}
          >
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.meta}>
              {item.domain} · {item.difficulty} · {item.safety}
            </Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: "#fafaf7" },
  input: {
    borderWidth: 1, borderColor: "#ccc", borderRadius: 6,
    padding: 12, fontSize: 16, marginBottom: 12, backgroundColor: "#fff",
  },
  row: { paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#eee" },
  title: { fontSize: 17, fontWeight: "600" },
  meta: { fontSize: 13, color: "#666", marginTop: 2 },
});
