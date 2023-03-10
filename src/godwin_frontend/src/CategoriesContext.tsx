import { Category, CategoryInfo } from "./../declarations/godwin_backend/godwin_backend.did";

import { godwin_backend } from "../declarations/godwin_backend";

import { useState, useEffect } from "react";

import React from 'react'

export const CategoriesContext = React.createContext<{categories: Map<Category, CategoryInfo>}>(
  {categories: new Map<Category, CategoryInfo>()}
);

export function useCategories() {
  
  const [categories, setCategories] = useState<Map<Category, CategoryInfo>>(new Map<Category, CategoryInfo>());

  const getCategories = async () => {
    const array = await godwin_backend.getCategories();
    let map = new Map<Category, CategoryInfo>();
    array.forEach((category) => {
      map.set(category[0], category[1]);
    });
    setCategories(map);
  };

  useEffect(() => {
    getCategories();
  }, []);

  return { categories };
}