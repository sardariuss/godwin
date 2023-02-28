import { CategoryArray__1 } from "./../declarations/godwin_backend/godwin_backend.did";

import { godwin_backend } from "../declarations/godwin_backend";

import { useState, useEffect } from "react";

import React from 'react'

export const CategoriesContext = React.createContext<{categories: CategoryArray__1;}>(
  {categories: []}
);

export function useCategories() {
  
  const [categories, setCategories] = useState<CategoryArray__1>([]);

  const getCategories = async () => {
    const categories = await godwin_backend.getCategories();
    setCategories(categories);
    console.log(categories);
  };

  useEffect(() => {
    getCategories();
  }, []);

  return { categories };
}