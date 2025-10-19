import { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, FlatList, StyleSheet, Alert } from 'react-native';
import { supabase } from '@/services/supabase';

interface Category {
  id: number;
  name: string;
  icon: string;
  property_limited_number: number;
  created_at: string;
}

export default function HomeScreen() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [name, setName] = useState('');
  const [icon, setIcon] = useState('📦');
  const [limitNumber, setLimitNumber] = useState('10');
  const [userId, setUserId] = useState<string | null>(null);

  // 初期化: ユーザー確認
  useEffect(() => {
    checkUser();
  }, []);

  const checkUser = async () => {
    console.log('🔍 ユーザー確認中...');
    const { data: { user }, error } = await supabase.auth.getUser();

    if (error) {
      console.error('❌ ユーザー取得エラー:', error);
      // 匿名サインイン
      await signInAnonymously();
      return;
    }

    if (user) {
      console.log('✅ ユーザー確認完了:', user.id);
      setUserId(user.id);
      loadCategories(user.id);
    } else {
      console.log('⚠️ ユーザー未ログイン - 匿名サインイン実行');
      await signInAnonymously();
    }
  };

  const signInAnonymously = async () => {
    // テスト用: 固定のテストユーザーでサインイン
    const testEmail = 'test@example.com';
    const testPassword = 'test123456';

    console.log('🔐 テストユーザーでサインイン試行...');

    // まずサインアップ試行
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
    });

    if (signUpError && signUpError.message.includes('already registered')) {
      // すでに登録済みならサインイン
      console.log('ℹ️ ユーザー登録済み - サインイン実行');
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });

      if (signInError) {
        console.error('❌ サインインエラー:', signInError);
        Alert.alert('エラー', 'サインインに失敗しました');
        return;
      }

      console.log('✅ サインイン成功:', signInData.user?.id);
      setUserId(signInData.user?.id || null);
      if (signInData.user) loadCategories(signInData.user.id);
    } else if (signUpError) {
      console.error('❌ サインアップエラー:', signUpError);
      Alert.alert('エラー', 'ユーザー作成に失敗しました');
    } else {
      console.log('✅ サインアップ成功:', signUpData.user?.id);
      setUserId(signUpData.user?.id || null);
      if (signUpData.user) {
        // users_profileテーブルにレコード作成
        await createUserProfile(signUpData.user.id);
        loadCategories(signUpData.user.id);
      }
    }
  };

  const createUserProfile = async (uid: string) => {
    console.log('👤 ユーザープロファイル作成中...');
    const { error } = await supabase
      .from('users_profile')
      .insert({ id: uid });

    if (error) {
      console.error('❌ プロファイル作成エラー:', error);
    } else {
      console.log('✅ プロファイル作成完了');
    }
  };

  const loadCategories = async (uid: string) => {
    console.log('📋 カテゴリー一覧取得中...');
    const { data, error } = await supabase
      .from('stuff_categories')
      .select('*')
      .eq('user_id', uid)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('❌ 取得エラー:', error);
      Alert.alert('エラー', 'カテゴリーの取得に失敗しました');
      return;
    }

    console.log('✅ カテゴリー取得完了:', data?.length, '件');
    console.log('📦 データ:', JSON.stringify(data, null, 2));
    setCategories(data || []);
  };

  const addCategory = async () => {
    if (!userId) {
      Alert.alert('エラー', 'ユーザーが未認証です');
      return;
    }

    if (!name.trim()) {
      Alert.alert('エラー', 'カテゴリー名を入力してください');
      return;
    }

    console.log('➕ カテゴリー追加中...');
    console.log('データ:', { name, icon, limitNumber });

    const { data, error } = await supabase
      .from('stuff_categories')
      .insert({
        user_id: userId,
        name: name.trim(),
        icon: icon || '📦',
        property_limited_number: parseInt(limitNumber) || 0,
      })
      .select()
      .single();

    if (error) {
      console.error('❌ 追加エラー:', error);
      Alert.alert('エラー', 'カテゴリーの追加に失敗しました');
      return;
    }

    console.log('✅ カテゴリー追加完了:', data);
    setName('');
    setIcon('📦');
    setLimitNumber('10');
    loadCategories(userId);
  };

  return (
    <View style={styles.container}>
      <Text>カテゴリーテスト</Text>
      {userId && <Text>User: {userId.slice(0, 8)}</Text>}

      <TextInput
        style={styles.input}
        placeholder="名前"
        value={name}
        onChangeText={setName}
      />
      <TextInput
        style={styles.input}
        placeholder="絵文字"
        value={icon}
        onChangeText={setIcon}
      />
      <Button title="追加" onPress={addCategory} />

      <Text>---</Text>
      <FlatList
        data={categories}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <Text>{item.icon} {item.name}</Text>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    paddingTop: 60,
  },
  input: {
    borderWidth: 1,
    padding: 8,
    marginVertical: 5,
  },
});
