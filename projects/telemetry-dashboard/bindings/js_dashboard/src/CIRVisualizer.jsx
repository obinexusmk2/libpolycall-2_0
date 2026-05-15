import React from "react";

export default function CIRVisualizer({ value }) {
  return <pre>{JSON.stringify(value, null, 2)}</pre>;
}
